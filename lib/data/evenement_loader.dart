// lib/data/evenement_loader.dart
// Charge les événements depuis evenements.json

import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/enums.dart';
import '../models/mercenaire.dart';
import '../models/etat_jeu.dart';
import '../models/models.dart';
import 'version_manager.dart';

class EvenementLoader {
  static Map<String, dynamic>? _data;
  static final Random _rng = Random();

  static Future<void> charger() async {
    if (_data != null) return;
    try {
      final raw = await rootBundle.loadString('assets/data/evenements.json');
      final cleaned = VersionManager._supprimerCommentaires(raw);
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final version = DataVersion.parse(json['version'] ?? '1.0.0');
      _data = VersionManager.migrer(json, 'evenements', version);
    } catch (e) {
      print('Erreur chargement evenements.json: $e');
      _data = {};
    }
  }

  // ══════════════════════════════════════════════════════
  // ÉVÉNEMENTS FIXES
  // ══════════════════════════════════════════════════════

  static List<EvenementJeu> getFixesJour(int jour) {
    if (_data == null) return [];
    final fixes = _data!['evenements_fixes'] as List? ?? [];
    return fixes
        .where((e) => e['jour'] == jour)
        .map(_parseEvenementFixe)
        .toList();
  }

  static EvenementJeu _parseEvenementFixe(Map<String, dynamic> e) {
    final consequence = e['consequence'] as Map<String, dynamic>? ?? {};
    BatimentType? batDecouvert;
    if (consequence['batimentDecouvert'] != null) {
      try {
        batDecouvert = BatimentType.values.firstWhere(
            (b) => b.name == consequence['batimentDecouvert']);
      } catch (_) {}
    }

    return EvenementJeu(
      id: e['id'],
      titre: e['titre'],
      texte: e['texte'],
      type: EvenementType.fixe,
      succes: ConsequenceEvenement(
        texteNarratif: e['texte'],
        batimentDecouvert: batDecouvert,
        recrueGratuite: consequence['recrueGratuite'] == true,
      ),
      echec: null,
    );
  }

  // ══════════════════════════════════════════════════════
  // ÉVÉNEMENTS DE POSTE
  // ══════════════════════════════════════════════════════

  static EvenementJeu? getEvenementPoste(
    Mercenaire merc,
    Substat substat,
    int valeurSubstat,
    EtatJeu etat,
  ) {
    if (_data == null) return null;
    final postes = _data!['evenements_poste'] as List? ?? [];

    // Trouver le bloc pour cette substat
    final bloc = postes.cast<Map<String, dynamic>>().firstWhere(
        (b) => b['substat'] == substat.name,
        orElse: () => {});
    if (bloc.isEmpty) return null;

    final templates = bloc['templates'] as List? ?? [];
    if (templates.isEmpty) return null;

    // Choisir le niveau selon la valeur de substat
    final niveau = valeurSubstat < 10
        ? 'debutant'
        : valeurSubstat < 30
            ? 'intermediaire'
            : 'expert';

    final template = templates.cast<Map<String, dynamic>>().firstWhere(
        (t) => t['niveau'] == niveau,
        orElse: () => templates.last as Map<String, dynamic>);

    // Calculer le seuil de défi
    final seuilDefi = (valeurSubstat * 0.8 + _rng.nextInt(10)).round()
        .clamp(3, 150);

    return _parseTemplatePoste(template, merc, substat, seuilDefi, etat);
  }

  static EvenementJeu _parseTemplatePoste(
    Map<String, dynamic> t,
    Mercenaire merc,
    Substat substat,
    int seuilDefi,
    EtatJeu etat,
  ) {
    final nom = merc.nom;
    final texte = (t['texte'] as String).replaceAll('{nom}', nom);
    final texteSucces = (t['texteSucces'] as String).replaceAll('{nom}', nom);
    final texteEchec = (t['texteEchec'] as String).replaceAll('{nom}', nom);

    return EvenementJeu(
      id: 'poste_${substat.name}_${etat.jour}',
      titre: t['titre'],
      texte: texte,
      type: EvenementType.poste,
      mercConcerneId: merc.id,
      seuilRequis: seuilDefi,
      substratRequise: substat,
      succes: _parseConsequence(t['succes'] ?? {}, texteSucces),
      echec: _parseConsequence(t['echec'] ?? {}, texteEchec),
    );
  }

  // ══════════════════════════════════════════════════════
  // ÉVÉNEMENTS ALÉATOIRES
  // ══════════════════════════════════════════════════════

  static EvenementJeu? getAleatoire(EtatJeu etat) {
    if (_data == null) return null;
    final aleatoires = _data!['evenements_aleatoires'] as List? ?? [];

    // Filtrer selon la renommée
    final eligibles = aleatoires.cast<Map<String, dynamic>>().where((e) {
      final renomMin = e['renommeeMin'] as String?;
      if (renomMin == null) return true;
      try {
        final niveau = RenommeeNiveau.values.firstWhere(
            (r) => r.name == renomMin);
        return etat.niveauRenommee.index >= niveau.index;
      } catch (_) {
        return true;
      }
    }).toList();

    if (eligibles.isEmpty) return null;

    // Vérifier les conditions spéciales
    final valides = eligibles.where((e) {
      final cond = e['conditionSpeciale'] as Map<String, dynamic>?;
      if (cond == null) return true;
      if (cond['classeRequise'] != null) {
        return etat.mercenaires.any(
            (m) => m.classeActuelle.id == cond['classeRequise'] ||
                m.historiqueClasses.any((c) => c.id == cond['classeRequise']));
      }
      return true;
    }).toList();

    if (valides.isEmpty) return null;

    // Tirage pondéré
    final total = valides.fold<int>(0, (s, e) => s + (e['poids'] as int? ?? 10));
    if (total == 0) return null;
    int tirage = _rng.nextInt(total);
    for (final evt in valides) {
      tirage -= evt['poids'] as int? ?? 10;
      if (tirage < 0) return _parseEvenementAleatoire(evt);
    }
    return _parseEvenementAleatoire(valides.last);
  }

  static EvenementJeu _parseEvenementAleatoire(Map<String, dynamic> e) {
    StatPrincipale? stat;
    if (e['statRequise'] != null) {
      try {
        stat = StatPrincipale.values.firstWhere(
            (s) => s.name == e['statRequise']);
      } catch (_) {}
    }

    final succes = e['succes'] != null
        ? _parseConsequence(e['succes'], e['succes']['texteSucces'] ?? '')
        : ConsequenceEvenement(texteNarratif: '');

    final echec = e['echec'] != null
        ? _parseConsequence(e['echec'], e['echec']['texteEchec'] ?? '')
        : null;

    return EvenementJeu(
      id: e['id'],
      titre: e['titre'],
      texte: e['texte'],
      type: EvenementType.aleatoire,
      seuilRequis: e['seuilRequis'],
      statRequise: stat,
      succes: succes,
      echec: echec,
    );
  }

  // ══════════════════════════════════════════════════════
  // PARSEUR DE CONSÉQUENCES
  // ══════════════════════════════════════════════════════

  static ConsequenceEvenement _parseConsequence(
    Map<String, dynamic> data,
    String texte,
  ) {
    BatimentType? batDecouvert;
    if (data['batimentDecouvert'] != null) {
      try {
        batDecouvert = BatimentType.values.firstWhere(
            (b) => b.name == data['batimentDecouvert']);
      } catch (_) {}
    }

    Substat? subBonus;
    if (data['substratBonus'] != null) {
      try {
        subBonus = Substat.values.firstWhere(
            (s) => s.name == data['substratBonus']);
      } catch (_) {}
    }

    GraviteBlessure? blessure;
    if (data['blessure'] != null) {
      try {
        blessure = GraviteBlessure.values.firstWhere(
            (g) => g.name == data['blessure']);
      } catch (_) {}
    }

    return ConsequenceEvenement(
      texteNarratif: texte,
      orGagne: data['orGagne'] as int?,
      orPerdu: data['orPerdu'] as int?,
      renommeeGainee: data['renommee'] as int?,
      substratBonus: subBonus,
      substratBonusMontant: data['montant'] as int? ?? 1,
      blessureMerc: blessure,
      batimentDecouvert: batDecouvert,
      indiceClasse: data['indiceClasse'] as String?,
      recrueGratuite: data['recrueGratuite'] == true,
    );
  }
}
