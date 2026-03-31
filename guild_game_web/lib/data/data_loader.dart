// lib/data/data_loader.dart
// Charge batiments.json et evenements.json — extensibles sans toucher au code

import 'dart:convert';
import 'package:flutter/services.dart';
import 'version_manager.dart';
import 'remote_loader.dart';

// ═══════════════════════════════════════════════════════
// MODÈLES DE DONNÉES CHARGÉES DEPUIS JSON
// ═══════════════════════════════════════════════════════

class BatimentData {
  final String id;
  final String nom;
  final String emoji;
  final int cout;
  final String? substat;
  final bool estSecret;
  final String description;
  final String? decouverte;
  final int? jourFixe;
  final String? conditionDecouverte;

  const BatimentData({
    required this.id,
    required this.nom,
    required this.emoji,
    required this.cout,
    this.substat,
    this.estSecret = false,
    required this.description,
    this.decouverte,
    this.jourFixe,
    this.conditionDecouverte,
  });

  factory BatimentData.fromJson(Map<String, dynamic> j) => BatimentData(
    id:          j['id'],
    nom:         j['nom'],
    emoji:       j['emoji'],
    cout:        j['cout'] ?? 0,
    substat:     j['substat'],
    estSecret:   j['secret'] ?? false,
    description: j['description'] ?? '',
    decouverte:  j['decouverte'],
    jourFixe:    j['jourFixe'],
    conditionDecouverte: j['conditionDecouverte'],
  );
}

class SubstatData {
  final String id;
  final String label;
  final String emoji;
  final String batiment;
  final bool estSecrete;

  const SubstatData({
    required this.id,
    required this.label,
    required this.emoji,
    required this.batiment,
    this.estSecrete = false,
  });

  factory SubstatData.fromJson(Map<String, dynamic> j) => SubstatData(
    id:         j['id'],
    label:      j['label'],
    emoji:      j['emoji'],
    batiment:   j['batiment'] ?? '',
    estSecrete: j['secret'] ?? false,
  );
}

class EvenementData {
  final String id;
  final String titre;
  final String texte;
  final String type;          // fixe | poste | aleatoire
  final int? jourFixe;
  final String? substat;      // pour les événements de poste
  final String? niveau;       // debutant | intermediaire | expert
  final int? seuilRequis;
  final String? substratRequise;
  final String? statRequise;
  final ConsequenceData succes;
  final ConsequenceData? echec;

  const EvenementData({
    required this.id,
    required this.titre,
    required this.texte,
    required this.type,
    this.jourFixe,
    this.substat,
    this.niveau,
    this.seuilRequis,
    this.substratRequise,
    this.statRequise,
    required this.succes,
    this.echec,
  });

  factory EvenementData.fromJson(Map<String, dynamic> j) => EvenementData(
    id:              j['id'],
    titre:           j['titre'],
    texte:           j['texte'],
    type:            j['type'],
    jourFixe:        j['jourFixe'],
    substat:         j['substat'],
    niveau:          j['niveau'],
    seuilRequis:     j['seuilRequis'],
    substratRequise: j['substratRequise'],
    statRequise:     j['statRequise'],
    succes: ConsequenceData.fromJson(j['succes'] as Map<String, dynamic>),
    echec:  j['echec'] != null
        ? ConsequenceData.fromJson(j['echec'] as Map<String, dynamic>)
        : null,
  );
}

class ConsequenceData {
  final String texteNarratif;
  final int? orGagne;
  final int? orPerdu;
  final String? substratBonus;
  final int? substratBonusMontant;
  final String? blessureMerc;
  final int? renommeeGainee;
  final String? batimentDecouvert;
  final String? batimentEndommage;
  final String? indiceClasse;

  const ConsequenceData({
    required this.texteNarratif,
    this.orGagne,
    this.orPerdu,
    this.substratBonus,
    this.substratBonusMontant,
    this.blessureMerc,
    this.renommeeGainee,
    this.batimentDecouvert,
    this.batimentEndommage,
    this.indiceClasse,
  });

  factory ConsequenceData.fromJson(Map<String, dynamic> j) => ConsequenceData(
    texteNarratif:       j['texteNarratif'] ?? '',
    orGagne:             j['orGagne'],
    orPerdu:             j['orPerdu'],
    substratBonus:       j['substratBonus'],
    substratBonusMontant: j['substratBonusMontant'],
    blessureMerc:        j['blessureMerc'],
    renommeeGainee:      j['renommeeGainee'],
    batimentDecouvert:   j['batimentDecouvert'],
    batimentEndommage:   j['batimentEndommage'],
    indiceClasse:        j['indiceClasse'],
  );
}

// ═══════════════════════════════════════════════════════
// LOADER PRINCIPAL
// ═══════════════════════════════════════════════════════

class DataLoader {
  // Cache
  static List<BatimentData>? _batiments;
  static List<SubstatData>? _substats;
  static List<EvenementData>? _evenements;

  // ── Chargement ──
  static Future<void> chargerTout() async {
    await Future.wait([
      _chargerBatiments(),
      _chargerEvenements(),
    ]);
  }

  static Future<void> _chargerBatiments() async {
    final raw = await _lireFichier('assets/data/batiments.json');
    if (raw == null) return;
    _batiments = (raw['batiments'] as List)
        .map((j) => BatimentData.fromJson(j as Map<String, dynamic>))
        .toList();
    _substats = (raw['substats'] as List)
        .map((j) => SubstatData.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<void> _chargerEvenements() async {
    final raw = await _lireFichier('assets/data/evenements.json');
    if (raw == null) return;
    _evenements = (raw['evenements'] as List)
        .map((j) => EvenementData.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ── Accesseurs ──
  static List<BatimentData> get batiments => _batiments ?? [];
  static List<SubstatData>  get substats  => _substats  ?? [];
  static List<EvenementData> get evenements => _evenements ?? [];

  static BatimentData? batiment(String id) {
    try { return batiments.firstWhere((b) => b.id == id); }
    catch (_) { return null; }
  }

  static SubstatData? substat(String id) {
    try { return substats.firstWhere((s) => s.id == id); }
    catch (_) { return null; }
  }

  // ── Événements par type ──
  static List<EvenementData> evenementsFixesPourJour(int jour) =>
      evenements.where((e) => e.type == 'fixe' && e.jourFixe == jour).toList();

  static List<EvenementData> evenementsPoste(String substatId, String niveau) =>
      evenements.where((e) =>
          e.type == 'poste' &&
          e.substat == substatId &&
          e.niveau == niveau).toList();

  static List<EvenementData> evenementsAleatoires() =>
      evenements.where((e) => e.type == 'aleatoire').toList();

  // ── Vérifier les mises à jour en arrière-plan ──
  static Future<MiseAJourResult> verifierMisesAJour() async {
    final result = await RemoteLoader.verifierMisesAJour();
    if (result.miseAJour) {
      // Recharger les données si mise à jour
      _batiments = null;
      _substats = null;
      _evenements = null;
      await chargerTout();
    }
    return result;
  }

  // ── Ajouter un nouveau bâtiment dynamiquement (depuis un évenement) ──
  static void ajouterBatiment(BatimentData b) {
    _batiments ??= [];
    if (!_batiments!.any((x) => x.id == b.id)) {
      _batiments!.add(b);
    }
  }

  // ── Lecture JSON ──
  static Future<Map<String, dynamic>?> _lireFichier(String path) async {
    try {
      // Utilise RemoteLoader — cache local si dispo, sinon assets
      final nom = path.split('/').last.replaceAll('.json', '');
      final raw = await RemoteLoader.charger(nom);
      final clean = VersionManager._supprimerCommentaires(raw);
      final data  = jsonDecode(clean) as Map<String, dynamic>;
      final ver   = DataVersion.parse(data['version'] ?? '1.0.0');
      return VersionManager.migrer(data, nom, ver);
    } catch (e) {
      print('DataLoader erreur $path: $e');
      return null;
    }
  }

  // ── Charger les objets ──
  static Future<Map<String, dynamic>> chargerObjets() async {
    final raw = await RemoteLoader.charger('objets');
    final clean = VersionManager._supprimerCommentaires(raw);
    final data = jsonDecode(clean) as Map<String, dynamic>;
    return data;
  }

  // ── Charger les recettes de bâtiments ──
  static Future<Map<String, dynamic>> chargerRecettes() async {
    final raw = await RemoteLoader.charger('recettes_batiments');
    final clean = VersionManager._supprimerCommentaires(raw);
    return jsonDecode(clean) as Map<String, dynamic>;
  }
}
