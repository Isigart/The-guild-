// lib/data/remote_loader.dart
// Chargement distant avec fallback local — fonctionne toujours hors ligne

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'version_manager.dart';

// ══════════════════════════════════════════════════════
// CONFIG — changer l'URL quand le repo GitHub est prêt
// ══════════════════════════════════════════════════════
class RemoteConfig {
  // Base URL du repo GitHub (raw content)
  // Exemple: 'https://raw.githubusercontent.com/TON_USER/guild-content/main'
  static const String baseUrl = ''; // vide = pas encore configuré

  static const Map<String, String> fichiers = {
    'classes_combattants': 'classes_combattants.json',
    'classes_civiles':     'classes_civiles.json',
    'classes_rares':       'classes_rares.json',
    'evenements':          'evenements.json',
    'batiments':           'batiments.json',
    'objets':             'objets.json',
    'zones':              'zones.json',
    'recettes_batiments': 'recettes_batiments.json',
  };

  static bool get estConfigure => baseUrl.isNotEmpty;
}

// ══════════════════════════════════════════════════════
// CACHE LOCAL — stocke les JSON téléchargés
// ══════════════════════════════════════════════════════
class ContentCache {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _ouvrir();
    return _db!;
  }

  static Future<Database> _ouvrir() async {
    final dbPath = path.join(await getDatabasesPath(), 'content_cache.db');
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE content_cache (
            fichier     TEXT PRIMARY KEY,
            version     TEXT NOT NULL,
            contenu     TEXT NOT NULL,
            telecharge  INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  static Future<String?> lire(String fichier) async {
    try {
      final rows = await (await db).query(
        'content_cache',
        where: 'fichier = ?',
        whereArgs: [fichier],
      );
      return rows.isNotEmpty ? rows.first['contenu'] as String : null;
    } catch (_) { return null; }
  }

  static Future<void> ecrire(String fichier, String version, String contenu) async {
    try {
      await (await db).insert('content_cache', {
        'fichier':    fichier,
        'version':    version,
        'contenu':    contenu,
        'telecharge': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}
  }

  static Future<String?> getVersion(String fichier) async {
    try {
      final rows = await (await db).query(
        'content_cache',
        columns: ['version'],
        where: 'fichier = ?',
        whereArgs: [fichier],
      );
      return rows.isNotEmpty ? rows.first['version'] as String : null;
    } catch (_) { return null; }
  }
}

// ══════════════════════════════════════════════════════
// REMOTE LOADER — logique principale
// ══════════════════════════════════════════════════════
class RemoteLoader {

  // ── Charger un fichier JSON (local + cache + distant) ──
  static Future<String> charger(String nomFichier) async {
    // 1. Essayer le cache local (téléchargé précédemment)
    final cache = await ContentCache.lire(nomFichier);
    if (cache != null) {
      return cache;
    }

    // 2. Fallback sur les assets locaux (toujours disponibles)
    return await _chargerLocal(nomFichier);
  }

  // ── Étape 1 : Vérifier si une mise à jour existe (sans télécharger) ──
  static Future<MiseAJourResult> verifierDisponibilite() async {
    if (!RemoteConfig.estConfigure) {
      return MiseAJourResult(succes: false, message: 'Serveur non configuré', miseAJour: false);
    }

    bool internetDisponible = false;
    try {
      final result = await InternetAddress.lookup('raw.githubusercontent.com')
          .timeout(const Duration(seconds: 3));
      internetDisponible = result.isNotEmpty;
    } catch (_) {}

    if (!internetDisponible) {
      return MiseAJourResult(succes: true, message: 'Hors ligne', miseAJour: false);
    }

    // Vérifier les versions sans télécharger le contenu complet
    final nouvellesVersions = <String, String>{};

    for (final entry in RemoteConfig.fichiers.entries) {
      final nomFichier = entry.key;
      final nomFichierJson = entry.value;
      try {
        // Télécharger seulement le manifeste de version (leger)
        final url = '${RemoteConfig.baseUrl}/$nomFichierJson';
        final contenu = await _telecharger(url);
        if (contenu == null) continue;

        final cleaned = VersionManager._supprimerCommentaires(contenu);
        final data = jsonDecode(cleaned) as Map<String, dynamic>;
        final versionDistante = data['version'] as String? ?? '1.0.0';
        final versionLocale = await ContentCache.getVersion(nomFichier) ?? '0.0.0';

        if (VersionManager.comparerVersions(versionDistante, versionLocale) > 0) {
          nouvellesVersions[nomFichier] = versionDistante;
          // Pré-mettre en cache pendant qu'on a le contenu
          await ContentCache.ecrire(nomFichier, versionDistante, contenu);
        }
      } catch (_) {}
    }

    final aUpdate = nouvellesVersions.isNotEmpty;
    final result = MiseAJourResult(
      succes: true,
      message: aUpdate
          ? '${nouvellesVersions.length} fichier(s) prêt(s) à installer'
          : 'Déjà à jour',
      miseAJour: aUpdate,
      telechargee: aUpdate, // déjà en cache, prête à appliquer
      nouvellesVersions: nouvellesVersions,
    );

    if (aUpdate) MiseAJourNotifier.setResultat(result);
    return result;
  }

  // ── Étape 2 : Appliquer la mise à jour (recharger DataLoader) ──
  static Future<void> appliquerMiseAJour() async {
    MiseAJourNotifier.effacer();
    // DataLoader rechargera depuis le cache au prochain appel
  }

  // Alias pour compatibilité
  static Future<MiseAJourResult> verifierMisesAJour() => verifierDisponibilite();

  // ── Forcer le rechargement depuis les assets locaux ──
  static Future<void> reinitialiserDepuisLocal() async {
    final database = await ContentCache.db;
    await database.delete('content_cache');
  }

  // ── Privé : charger depuis les assets Flutter ──
  static Future<String> _chargerLocal(String nomFichier) async {
    return await rootBundle.loadString('assets/data/$nomFichier.json');
  }

  // ── Privé : télécharger depuis l'URL ──
  static Future<String?> _telecharger(String url) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return await response.transform(utf8.decoder).join();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

// ══════════════════════════════════════════════════════
// RÉSULTAT
// ══════════════════════════════════════════════════════
class MiseAJourResult {
  final bool succes;
  final String message;
  final bool miseAJour;         // true = nouvelle version disponible
  final bool telechargee;       // true = déjà téléchargée
  final List<String> erreurs;
  final Map<String, String> nouvellesVersions; // fichier → nouvelle version

  const MiseAJourResult({
    required this.succes,
    required this.message,
    required this.miseAJour,
    this.telechargee = false,
    this.erreurs = const [],
    this.nouvellesVersions = const {},
  });
}

// ══════════════════════════════════════════════════════
// NOTIFICATION — provider Riverpod pour l'UI
// ══════════════════════════════════════════════════════
class MiseAJourNotifier {
  static MiseAJourResult? _resultatEnAttente;

  static MiseAJourResult? get resultatEnAttente => _resultatEnAttente;
  static bool get miseAJourDisponible => _resultatEnAttente?.miseAJour == true;

  static void setResultat(MiseAJourResult r) => _resultatEnAttente = r;
  static void effacer() => _resultatEnAttente = null;
}
