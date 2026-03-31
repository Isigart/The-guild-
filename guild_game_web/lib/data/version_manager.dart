// lib/data/version_manager.dart
// Gestion des versions des bases de données JSON

import 'dart:convert';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════
// VERSION ACTUELLE DU JEU
// ═══════════════════════════════════════════════════════
const String kGameVersion = '1.0.0';

class DataVersion {
  final int major;
  final int minor;
  final int patch;

  const DataVersion(this.major, this.minor, this.patch);

  factory DataVersion.parse(String version) {
    final parts = version.split('.').map(int.parse).toList();
    return DataVersion(
      parts.length > 0 ? parts[0] : 1,
      parts.length > 1 ? parts[1] : 0,
      parts.length > 2 ? parts[2] : 0,
    );
  }

  bool operator >=(DataVersion other) {
    if (major != other.major) return major >= other.major;
    if (minor != other.minor) return minor >= other.minor;
    return patch >= other.patch;
  }

  bool operator >(DataVersion other) {
    if (major != other.major) return major > other.major;
    if (minor != other.minor) return minor > other.minor;
    return patch > other.patch;
  }

  @override
  String toString() => '$major.$minor.$patch';
}

// ═══════════════════════════════════════════════════════
// MANIFESTE — liste toutes les versions de chaque fichier
// ═══════════════════════════════════════════════════════
class DataManifest {
  static const Map<String, String> fichiers = {
    'classes_combattants': 'assets/data/classes_combattants.json',
    'classes_civiles':     'assets/data/classes_civiles.json',
    'classes_rares':       'assets/data/classes_rares.json',
    'evenements':          'assets/data/evenements.json',
    'ennemis':             'assets/data/ennemis.json',
    'zones':               'assets/data/zones.json',
  };

  // Versions minimales requises pour chaque fichier
  static const Map<String, String> versionsRequises = {
    'classes_combattants': '1.0.0',
    'classes_civiles':     '1.0.0',
    'classes_rares':       '1.0.0',
    'evenements':          '1.0.0',
    'ennemis':             '1.0.0',
    'zones':               '1.0.0',
  };
}

// ═══════════════════════════════════════════════════════
// RÉSULTAT DE VÉRIFICATION
// ═══════════════════════════════════════════════════════
class VersionCheckResult {
  final bool ok;
  final List<String> erreurs;
  final List<String> avertissements;
  final Map<String, DataVersion> versionsChargees;

  const VersionCheckResult({
    required this.ok,
    this.erreurs = const [],
    this.avertissements = const [],
    this.versionsChargees = const {},
  });
}

// ═══════════════════════════════════════════════════════
// GESTIONNAIRE DE VERSIONS
// ═══════════════════════════════════════════════════════
class VersionManager {
  static final DataVersion _versionJeu = DataVersion.parse(kGameVersion);

  // ── Vérifier tous les fichiers au démarrage ──
  static Future<VersionCheckResult> verifierTout() async {
    final erreurs = <String>[];
    final avertissements = <String>[];
    final versionsChargees = <String, DataVersion>{};

    for (final entry in DataManifest.fichiers.entries) {
      final nom = entry.key;
      final chemin = entry.value;

      try {
        final data = await _lireMeta(chemin);
        if (data == null) {
          // Fichier optionnel manquant → avertissement
          avertissements.add('$nom : fichier introuvable (optionnel)');
          continue;
        }

        final version = DataVersion.parse(data['version'] ?? '1.0.0');
        final minRequis = DataVersion.parse(DataManifest.versionsRequises[nom] ?? '1.0.0');
        versionsChargees[nom] = version;

        // Vérifier compatibilité
        if (!(version >= minRequis)) {
          erreurs.add('$nom v$version trop ancien — requis v$minRequis+');
        }

        // Vérifier compatibilité avec la version du jeu
        final minGame = DataVersion.parse(data['minGameVersion'] ?? '1.0.0');
        if (!(_versionJeu >= minGame)) {
          erreurs.add('$nom requiert jeu v$minGame — actuel v$_versionJeu');
        }

        // Avertir si version majeure différente (breaking changes possibles)
        if (version.major > _versionJeu.major) {
          avertissements.add('$nom v$version est plus récent que le jeu v$_versionJeu — migration possible');
        }

      } catch (e) {
        erreurs.add('$nom : erreur lecture — $e');
      }
    }

    return VersionCheckResult(
      ok: erreurs.isEmpty,
      erreurs: erreurs,
      avertissements: avertissements,
      versionsChargees: versionsChargees,
    );
  }

  // ── Lire uniquement les métadonnées d'un fichier ──
  static Future<Map<String, dynamic>?> _lireMeta(String chemin) async {
    try {
      final data = await rootBundle.loadString(chemin);
      final cleaned = _supprimerCommentaires(data);
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return {
        'version': json['version'],
        'minGameVersion': json['minGameVersion'],
        'description': json['description'],
        'changelog': json['changelog'],
      };
    } catch (_) {
      return null;
    }
  }

  // ── Appliquer une migration si nécessaire ──
  static Map<String, dynamic> migrer(
    Map<String, dynamic> data,
    String nomFichier,
    DataVersion versionSource,
  ) {
    var result = Map<String, dynamic>.from(data);

    // Migrations par version
    // Quand tu changes un JSON, ajoute ici la migration correspondante
    
    // Exemple : migration 1.0.0 → 1.1.0
    // if (versionSource < DataVersion(1, 1, 0)) {
    //   result = _migrer_1_0_to_1_1(result, nomFichier);
    // }
    
    // Exemple : migration 1.1.0 → 2.0.0
    // if (versionSource < DataVersion(2, 0, 0)) {
    //   result = _migrer_1_1_to_2_0(result, nomFichier);
    // }

    return result;
  }

  // ── Nettoyer les commentaires JS du JSON ──
  static String _supprimerCommentaires(String json) {
    final lines = json.split('\n');
    return lines.map((line) {
      // Trouver // hors des strings
      bool inString = false;
      for (int i = 0; i < line.length; i++) {
        if (line[i] == '"' && (i == 0 || line[i-1] != '\\')) {
          inString = !inString;
        }
        if (!inString && i < line.length - 1 &&
            line[i] == '/' && line[i+1] == '/') {
          return line.substring(0, i).trimRight();
        }
      }
      return line;
    }).join('\n');
  }

  // ── Comparer deux versions ──
  static int comparerVersions(String v1, String v2) {
    final dv1 = DataVersion.parse(v1);
    final dv2 = DataVersion.parse(v2);
    if (dv1 > dv2) return 1;
    if (dv2 > dv1) return -1;
    return 0;
  }
}

// ═══════════════════════════════════════════════════════
// EXEMPLE : Migration 1.0.0 → 1.1.0
// Décommente et adapte quand tu modifie un JSON
// ═══════════════════════════════════════════════════════
//
// Map<String, dynamic> _migrer_1_0_to_1_1(
//   Map<String, dynamic> data,
//   String nomFichier,
// ) {
//   if (nomFichier == 'classes_combattants') {
//     // Exemple : renommer un champ
//     final classes = data['classes'] as List;
//     for (final cls in classes) {
//       // Ancien champ 'reqStat' → nouveau 'reqStats'
//       if (cls['reqStat'] != null) {
//         cls['reqStats'] = cls['reqStat'];
//         cls.remove('reqStat');
//       }
//       // Ajouter un champ manquant avec valeur par défaut
//       cls['affinites'] ??= [];
//     }
//   }
//   return data;
// }
