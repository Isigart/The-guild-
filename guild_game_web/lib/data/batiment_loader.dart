// lib/data/batiment_loader.dart
// Charge les bâtiments et substats depuis batiments.json

import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/enums.dart';
import 'version_manager.dart';

class BatimentData {
  final String id;
  final String nom;
  final String emoji;
  final String? substatId;
  final int cout;
  final bool secret;
  final bool gratuit;
  final String description;
  final int niveauxMax;
  final List<int> slotsParNiveau;
  final String? effetSpecial;
  final Map<String, dynamic>? decouverte;
  final Map<String, dynamic>? effetNegatif;

  const BatimentData({
    required this.id,
    required this.nom,
    required this.emoji,
    this.substatId,
    required this.cout,
    required this.secret,
    required this.description,
    required this.niveauxMax,
    required this.slotsParNiveau,
    this.effetSpecial,
    this.decouverte,
    this.effetNegatif,
    this.gratuit = false,
  });
}

class SubstatData {
  final String id;
  final String label;
  final String description;

  const SubstatData({
    required this.id,
    required this.label,
    required this.description,
  });
}

class BatimentLoader {
  static List<BatimentData>? _batiments;
  static List<SubstatData>? _substats;
  static Map<String, BatimentData>? _indexParId;
  static Map<String, SubstatData>? _substatIndex;

  static Future<void> charger() async {
    if (_batiments != null) return;

    try {
      final raw = await rootBundle.loadString('assets/data/batiments.json');
      final cleaned = VersionManager._supprimerCommentaires(raw);
      final json = jsonDecode(cleaned) as Map<String, dynamic>;

      // Appliquer migration si nécessaire
      final version = DataVersion.parse(json['version'] ?? '1.0.0');
      final data = VersionManager.migrer(json, 'batiments', version);

      // Parser substats
      _substats = (data['substats'] as List)
          .map((s) => SubstatData(
                id: s['id'],
                label: s['label'],
                description: s['description'],
              ))
          .toList();

      // Parser bâtiments
      _batiments = (data['batiments'] as List)
          .map((b) => BatimentData(
                id: b['id'],
                nom: b['nom'],
                emoji: b['emoji'],
                substatId: b['substat'],
                cout: b['cout'] ?? 0,
                secret: b['secret'] ?? false,
                gratuit: b['gratuit'] ?? false,
                description: b['description'] ?? '',
                niveauxMax: b['niveauxMax'] ?? 1,
                slotsParNiveau: List<int>.from(b['slotsParNiveau'] ?? [1]),
                effetSpecial: b['effetSpecial'],
                decouverte: b['decouverte'],
                effetNegatif: b['effetNegatif'],
              ))
          .toList();

      // Index
      _indexParId = {for (final b in _batiments!) b.id: b};
      _substatIndex = {for (final s in _substats!) s.id: s};

    } catch (e) {
      print('Erreur chargement batiments.json: $e');
      _batiments = [];
      _substats = [];
      _indexParId = {};
      _substatIndex = {};
    }
  }

  // ── Accesseurs ──
  static List<BatimentData> get batiments => _batiments ?? [];
  static List<SubstatData> get substats => _substats ?? [];

  static BatimentData? getById(String id) => _indexParId?[id];
  static SubstatData? getSubstat(String id) => _substatIndex?[id];

  static List<BatimentData> get normaux =>
      batiments.where((b) => !b.secret).toList();

  static List<BatimentData> get secrets =>
      batiments.where((b) => b.secret).toList();

  static List<BatimentData> get decouvrablesJourFixe =>
      secrets.where((b) =>
          b.decouverte?['type'] == 'fixe').toList();

  // Bâtiments découvrables à un jour précis
  static List<BatimentData> getDecouvertesJour(int jour) =>
      decouvrablesJourFixe.where((b) =>
          b.decouverte?['jour'] == jour).toList();

  // Convertir l'ID de substat en enum Substat
  static Substat? substatEnum(String? id) {
    if (id == null) return null;
    try {
      return Substat.values.firstWhere((s) => s.name == id);
    } catch (_) {
      return null;
    }
  }

  // Convertir l'ID de bâtiment en enum BatimentType
  static BatimentType? batimentTypeEnum(String id) {
    try {
      return BatimentType.values.firstWhere((t) => t.name == id);
    } catch (_) {
      return null;
    }
  }
}
