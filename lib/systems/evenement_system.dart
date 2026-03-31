// lib/systems/evenement_system.dart
// Système d'événements v2.0
// 3 catégories : progression, aleatoire, metier
// Max 1 par catégorie par jour = max 3 événements

import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/enums.dart';
import '../models/mercenaire.dart';
import '../models/models.dart';
import '../models/etat_jeu.dart';

// ══════════════════════════════════════════════════════
// MODÈLES
// ══════════════════════════════════════════════════════

class Declencheur {
  final int?    jourFixe;
  final int?    jourMin;
  final int?    renommeeMin;
  final String? zoneVaincue;
  final String? zoneDebloquee;
  final String? evenementVu;
  final String? choixPris;
  final int?    delaiMin;
  final String? objetDansCoffre;
  final String? objetVientEtreObtenu;
  final String? classeDebloquee;
  final String? recrueSpeciale;
  final String? batimentExiste;
  final Map<String, int>? batimentNiveau;
  final int?    orMin;
  final Map<String, int>? substratMin;

  const Declencheur({
    this.jourFixe, this.jourMin, this.renommeeMin,
    this.zoneVaincue, this.zoneDebloquee,
    this.evenementVu, this.choixPris, this.delaiMin,
    this.objetDansCoffre, this.objetVientEtreObtenu,
    this.classeDebloquee, this.recrueSpeciale,
    this.batimentExiste, this.batimentNiveau,
    this.orMin, this.substratMin,
  });

  factory Declencheur.fromJson(Map<String, dynamic> j) => Declencheur(
    jourFixe:    (j['jourFixe']    as num?)?.toInt(),
    jourMin:     (j['jourMin']     as num?)?.toInt(),
    renommeeMin: (j['renommeeMin'] as num?)?.toInt(),
    zoneVaincue:  j['zoneVaincue']  as String?,
    zoneDebloquee: j['zoneDebloquee'] as String?,
    evenementVu:  j['evenementVu']  as String?,
    choixPris:    j['choixPris']    as String?,
    delaiMin:    (j['delaiMin']    as num?)?.toInt(),
    objetDansCoffre:       j['objetDansCoffre']       as String?,
    objetVientEtreObtenu:  j['objetVientEtreObtenu']  as String?,
    classeDebloquee:       j['classeDebloquee']        as String?,
    recrueSpeciale:        j['recrueSpeciale']         as String?,
    batimentExiste:        j['batimentExiste']         as String?,
    batimentNiveau: (j['batimentNiveau'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, (v as num).toInt())),
    orMin:       (j['orMin']       as num?)?.toInt(),
    substratMin: (j['substratMin'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, (v as num).toInt())),
  );
}

class ConsequencesEvenement {
  final int?    orGagne;
  final int?    orPerdu;
  final Map<String, int>? objetGagne;
  final Map<String, int>? substratBonus;
  final Map<String, int>? statBonus;
  final String? blessure;
  final Map<String, dynamic>? blessureAleatoire;
  final bool    mercenaireGagne;
  final String? recrueSpeciale;
  final int?    renommeeBonus;
  final int?    renommeePerte;
  final String? batimentDecouvert;
  final bool    batimentEndommage;
  final bool    batimentDetruit;
  final String? classeDebloquee;
  final String? classeIndice;
  final String? evenementDebloque;
  final String? chaineTerminee;
  final String? texteResultat;

  const ConsequencesEvenement({
    this.orGagne, this.orPerdu,
    this.objetGagne, this.substratBonus, this.statBonus,
    this.blessure, this.blessureAleatoire,
    this.mercenaireGagne = false,
    this.recrueSpeciale,
    this.renommeeBonus, this.renommeePerte,
    this.batimentDecouvert,
    this.batimentEndommage = false,
    this.batimentDetruit = false,
    this.classeDebloquee, this.classeIndice,
    this.evenementDebloque, this.chaineTerminee,
    this.texteResultat,
  });

  factory ConsequencesEvenement.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const ConsequencesEvenement();
    return ConsequencesEvenement(
      orGagne:    (j['orGagne']    as num?)?.toInt(),
      orPerdu:    (j['orPerdu']    as num?)?.toInt(),
      objetGagne: (j['objetGagne'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toInt())),
      substratBonus: (j['substratBonus'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toInt())),
      statBonus: (j['statBonus'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toInt())),
      blessure:   j['blessure']   as String?,
      blessureAleatoire: j['blessureAleatoire'] as Map<String, dynamic>?,
      mercenaireGagne:   j['mercenaireGagne']   as bool? ?? false,
      recrueSpeciale:    j['recrueSpeciale']     as String?,
      renommeeBonus:    (j['renommeeBonus']     as num?)?.toInt(),
      renommeePerte:    (j['renommeePerte']     as num?)?.toInt(),
      batimentDecouvert: j['batimentDecouvert'] as String?,
      batimentEndommage: j['batimentEndommage'] as bool? ?? false,
      batimentDetruit:   j['batimentDetruit']   as bool? ?? false,
      classeDebloquee:   j['classeDebloquee']   as String?,
      classeIndice:      j['classeIndice']       as String?,
      evenementDebloque: j['evenementDebloque'] as String?,
      chaineTerminee:    j['chaineTerminee']     as String?,
      texteResultat:     j['texteResultat']      as String?,
    );
  }

  bool get estVide => orGagne == null && orPerdu == null &&
      objetGagne == null && substratBonus == null &&
      mercenaireGagne == false && renommeeBonus == null &&
      texteResultat == null;
}

class ChoixEvenement {
  final String id;
  final String texte;
  final Map<String, dynamic>? conditionVisible;
  final Map<String, dynamic>? check;
  final ConsequencesEvenement consequences;
  final ConsequencesEvenement? consequencesSucces;
  final ConsequencesEvenement? consequencesEchec;

  const ChoixEvenement({
    required this.id,
    required this.texte,
    this.conditionVisible,
    this.check,
    required this.consequences,
    this.consequencesSucces,
    this.consequencesEchec,
  });

  factory ChoixEvenement.fromJson(Map<String, dynamic> j) => ChoixEvenement(
    id:    j['id']    as String? ?? 'choix',
    texte: j['texte'] as String? ?? '',
    conditionVisible: j['conditionVisible'] as Map<String, dynamic>?,
    check:            j['check']            as Map<String, dynamic>?,
    consequences: ConsequencesEvenement.fromJson(
        j['consequences'] as Map<String, dynamic>?),
    consequencesSucces: j['consequencesSucces'] != null
        ? ConsequencesEvenement.fromJson(j['consequencesSucces'] as Map<String, dynamic>)
        : null,
    consequencesEchec: j['consequencesEchec'] != null
        ? ConsequencesEvenement.fromJson(j['consequencesEchec'] as Map<String, dynamic>)
        : null,
  );
}

class Evenement {
  final String id;
  final String titre;
  final String texte;
  final String emoji;
  final String categorie;
  final String? substat;
  final String? niveauSubstat;
  final double probabilite;
  final bool repetable;
  final List<Declencheur> declencheurs;
  final List<ChoixEvenement> choix;
  final Map<String, dynamic>? check;
  final ConsequencesEvenement? consequences;
  final ConsequencesEvenement? consequencesSucces;
  final ConsequencesEvenement? consequencesEchec;

  const Evenement({
    required this.id,
    required this.titre,
    required this.texte,
    this.emoji = '📜',
    this.categorie = 'aleatoire',
    this.substat,
    this.niveauSubstat,
    this.probabilite = 1.0,
    this.repetable = false,
    this.declencheurs = const [],
    this.choix = const [],
    this.check,
    this.consequences,
    this.consequencesSucces,
    this.consequencesEchec,
  });

  bool get aDesChoix => choix.isNotEmpty;

  factory Evenement.fromJson(Map<String, dynamic> j) => Evenement(
    id:        j['id']        as String,
    titre:     j['titre']     as String? ?? '',
    texte:     j['texte']     as String? ?? '',
    emoji:     j['emoji']     as String? ?? '📜',
    categorie: j['categorie'] as String? ?? 'aleatoire',
    substat:   j['substat']   as String?,
    niveauSubstat: j['niveauSubstat'] as String?,
    probabilite: (j['probabilite'] as num?)?.toDouble() ?? 1.0,
    repetable:   j['repetable']   as bool? ?? false,
    declencheurs: (j['declencheurs'] as List<dynamic>? ?? [])
        .map((d) => Declencheur.fromJson(d as Map<String, dynamic>))
        .toList(),
    choix: (j['choix'] as List<dynamic>? ?? [])
        .map((c) => ChoixEvenement.fromJson(c as Map<String, dynamic>))
        .toList(),
    check: j['check'] as Map<String, dynamic>?,
    consequences: ConsequencesEvenement.fromJson(
        j['consequences'] as Map<String, dynamic>?),
    consequencesSucces: j['consequencesSucces'] != null
        ? ConsequencesEvenement.fromJson(j['consequencesSucces'] as Map<String, dynamic>)
        : null,
    consequencesEchec: j['consequencesEchec'] != null
        ? ConsequencesEvenement.fromJson(j['consequencesEchec'] as Map<String, dynamic>)
        : null,
  );
}

// ── Résultat d'un événement résolu ──
class ResultatEvenement {
  final String evenementId;
  final String? choixId;
  final ConsequencesEvenement consequences;
  final String texteAffiche;
  final bool estSucces;

  const ResultatEvenement({
    required this.evenementId,
    this.choixId,
    required this.consequences,
    required this.texteAffiche,
    this.estSucces = true,
  });
}

// ── Chaîne en cours — pour le journal du joueur ──
class ChaineEnCours {
  final String id;
  final String titreChaine;
  final String derniereEtapeId;
  final String resumeDerniere;
  final int jourDerniere;
  bool terminee;

  ChaineEnCours({
    required this.id,
    required this.titreChaine,
    required this.derniereEtapeId,
    required this.resumeDerniere,
    required this.jourDerniere,
    this.terminee = false,
  });
}

// ══════════════════════════════════════════════════════
// SYSTÈME PRINCIPAL
// ══════════════════════════════════════════════════════

class EvenementSystem {
  final Random _rng = Random();
  List<Evenement> _evenements = [];
  bool _charge = false;

  Future<void> initialiser() async {
    if (_charge) return;
    try {
      final raw = await rootBundle.loadString('assets/data/evenements.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _evenements = (data['evenements'] as List<dynamic>? ?? [])
          .map((e) => Evenement.fromJson(e as Map<String, dynamic>))
          .toList();
      _charge = true;
    } catch (e) {
      print('EvenementSystem erreur: $e');
    }
  }

  // ══════════════════════════════════════════════════════
  // SÉLECTION MAX 1 PAR CATÉGORIE
  // ══════════════════════════════════════════════════════

  List<Evenement> selectionnerEvenementsJour(
    EtatJeu etat, {
    String? objetVientEtreObtenu,
    String? classeVientEtreDebloquee,
    String? recrueVientDeRejoindre,
    String? zoneVaincrueAujourdhui,
  }) {
    final ctx = _Ctx(
      etat: etat,
      objetObtenu:     objetVientEtreObtenu,
      classeDebloquee: classeVientEtreDebloquee,
      recrueSpeciale:  recrueVientDeRejoindre,
      zoneVaincue:     zoneVaincrueAujourdhui,
    );

    final progression = _selectionnerUn('progression', ctx);
    final aleatoire   = _selectionnerUn('aleatoire',   ctx);
    final metier      = _selectionnerMetier(ctx);

    return [progression, aleatoire, metier].whereType<Evenement>().toList();
  }

  Evenement? _selectionnerUn(String categorie, _Ctx ctx) {
    final candidats = _evenements
        .where((e) => e.categorie == categorie)
        .where((e) => _estDeclenche(e, ctx))
        .where((e) => e.repetable || !ctx.etat.evenementsVus.contains(e.id))
        .toList();

    if (candidats.isEmpty) return null;

    // Progression : déterministe — premier candidat prioritaire
    if (categorie == 'progression') return candidats.first;

    // Aléatoire : tirage pondéré
    final eligibles = candidats
        .where((e) => _rng.nextDouble() < e.probabilite)
        .toList();
    if (eligibles.isEmpty) return null;
    return eligibles[_rng.nextInt(eligibles.length)];
  }

  Evenement? _selectionnerMetier(_Ctx ctx) {
    final etat = ctx.etat;
    final candidats = <Evenement>[];

    for (final merc in etat.mercenairesAuPoste) {
      if (merc.posteAssigneId == null) continue;
      final bat = etat.batiments.firstWhere(
        (b) => b.id == merc.posteAssigneId,
        orElse: () => Batiment(id: '', type: BatimentType.bureauDeRecrutement),
      );
      if (!bat.estFonctionnel) continue;

      final substat = bat.type.substat;
      if (substat == null) continue;

      final valeur = merc.getSubstat(substat);
      final chance = (valeur / 50.0) * (bat.niveau / 3.0) * 0.10;
      if (_rng.nextDouble() > chance) continue;

      final niveau = valeur < 15 ? 'debutant'
                   : valeur < 30 ? 'intermediaire'
                   : 'expert';

      final evs = _evenements
          .where((e) => e.categorie == 'metier')
          .where((e) => e.substat == substat.name)
          .where((e) => e.niveauSubstat == niveau)
          .where((e) => !ctx.etat.evenementsVus.contains(e.id))
          .toList();

      candidats.addAll(evs);
    }

    if (candidats.isEmpty) return null;
    return candidats[_rng.nextInt(candidats.length)];
  }

  // ══════════════════════════════════════════════════════
  // VÉRIFICATION DES DÉCLENCHEURS
  // ══════════════════════════════════════════════════════

  bool _estDeclenche(Evenement e, _Ctx ctx) {
    if (e.declencheurs.isEmpty) return true;
    return e.declencheurs.any((d) => _verifier(d, ctx));
  }

  bool _verifier(Declencheur d, _Ctx ctx) {
    final etat = ctx.etat;

    if (d.jourFixe    != null && etat.jour     != d.jourFixe)    return false;
    if (d.jourMin     != null && etat.jour      < d.jourMin!)     return false;
    if (d.renommeeMin != null && etat.renommee  < d.renommeeMin!) return false;
    if (d.orMin       != null && etat.or        < d.orMin!)       return false;

    if (d.zoneVaincue != null && ctx.zoneVaincue != d.zoneVaincue) return false;

    if (d.zoneDebloquee != null) {
      final n = int.tryParse(d.zoneDebloquee!.replaceAll('zone_', '')) ?? 0;
      if (!etat.zones.any((z) => z.numero == n && z.etat != ZoneEtat.inconnue)) return false;
    }

    if (d.evenementVu != null) {
      if (!etat.evenementsVus.contains(d.evenementVu)) return false;
      if (d.choixPris != null && etat.choixPris[d.evenementVu!] != d.choixPris) return false;
      if (d.delaiMin  != null) {
        final jourVu = etat.jourEvenementVu[d.evenementVu!] ?? 0;
        if (etat.jour - jourVu < d.delaiMin!) return false;
      }
    }

    if (d.objetDansCoffre      != null && !etat.coffreGuilde.aAssez(d.objetDansCoffre!, 1)) return false;
    if (d.objetVientEtreObtenu != null && ctx.objetObtenu     != d.objetVientEtreObtenu)    return false;
    if (d.classeDebloquee      != null && ctx.classeDebloquee != d.classeDebloquee)          return false;
    if (d.recrueSpeciale       != null && ctx.recrueSpeciale  != d.recrueSpeciale)           return false;

    if (d.batimentExiste != null) {
      if (!etat.batiments.any((b) => b.type.name == d.batimentExiste && b.estFonctionnel)) return false;
    }

    if (d.batimentNiveau != null) {
      for (final entry in d.batimentNiveau!.entries) {
        final bat = etat.batiments.firstWhere(
          (b) => b.type.name == entry.key,
          orElse: () => Batiment(id: '', type: BatimentType.bureauDeRecrutement),
        );
        if (bat.niveau < entry.value) return false;
      }
    }

    if (d.substratMin != null) {
      for (final entry in d.substratMin!.entries) {
        final sub = Substat.values.firstWhere(
          (s) => s.name == entry.key, orElse: () => Substat.nature);
        final max = etat.mercenaires
            .map((m) => m.getSubstat(sub))
            .fold(0, (a, b) => a > b ? a : b);
        if (max < entry.value) return false;
      }
    }

    return true;
  }

  // ══════════════════════════════════════════════════════
  // RÉSOLUTION
  // ══════════════════════════════════════════════════════

  ResultatEvenement resoudre({
    required Evenement evenement,
    required String? choixId,
    required EtatJeu etat,
  }) {
    if (evenement.aDesChoix && choixId != null) {
      final choix = evenement.choix.firstWhere(
        (c) => c.id == choixId, orElse: () => evenement.choix.first);
      return _resoudreChoix(evenement, choix, etat);
    }

    if (evenement.check != null) {
      return _resoudreAvecCheck(
        evenement.id, null, evenement.check!,
        evenement.consequencesSucces, evenement.consequencesEchec, etat);
    }

    final cons = evenement.consequences ?? const ConsequencesEvenement();
    return ResultatEvenement(
      evenementId: evenement.id,
      consequences: cons,
      texteAffiche: cons.texteResultat ?? '',
    );
  }

  ResultatEvenement _resoudreChoix(Evenement ev, ChoixEvenement choix, EtatJeu etat) {
    if (choix.check != null) {
      return _resoudreAvecCheck(
        ev.id, choix.id, choix.check!,
        choix.consequencesSucces, choix.consequencesEchec, etat);
    }
    final cons = choix.consequences;
    return ResultatEvenement(
      evenementId: ev.id,
      choixId: choix.id,
      consequences: cons,
      texteAffiche: cons.texteResultat ?? '',
    );
  }

  ResultatEvenement _resoudreAvecCheck(
    String evId, String? choixId,
    Map<String, dynamic> check,
    ConsequencesEvenement? succes,
    ConsequencesEvenement? echec,
    EtatJeu etat,
  ) {
    final ok  = _evaluerCheck(check, etat);
    final cons = ok ? (succes ?? const ConsequencesEvenement())
                    : (echec  ?? const ConsequencesEvenement());
    return ResultatEvenement(
      evenementId: evId,
      choixId: choixId,
      consequences: cons,
      texteAffiche: cons.texteResultat ?? (ok ? 'Succès.' : 'Échec.'),
      estSucces: ok,
    );
  }

  bool _evaluerCheck(Map<String, dynamic> check, EtatJeu etat) {
    final type  = check['stat'] as String? ?? check['substat'] as String?;
    final seuil = (check['seuil'] as num?)?.toInt() ?? 0;
    if (type == null) return true;

    final statP = StatPrincipale.values
        .where((s) => s.name.toUpperCase() == type.toUpperCase())
        .firstOrNull;
    if (statP != null) {
      return etat.mercenaires
          .where((m) => m.estDisponible)
          .map((m) => m.stats[statP] ?? 0)
          .fold(0, (a, b) => a > b ? a : b) >= seuil;
    }

    final sub = Substat.values.where((s) => s.name == type).firstOrNull;
    if (sub != null) {
      return etat.mercenaires
          .map((m) => m.getSubstat(sub))
          .fold(0, (a, b) => a > b ? a : b) >= seuil;
    }
    return true;
  }

  // ══════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════

  bool choixVisible(ChoixEvenement choix, EtatJeu etat) {
    final cond = choix.conditionVisible;
    if (cond == null) return true;
    if (cond['orMin'] != null && etat.or < (cond['orMin'] as num).toInt()) return false;
    if (cond['zoneDebloquee'] != null) {
      final n = int.tryParse((cond['zoneDebloquee'] as String).replaceAll('zone_', '')) ?? 0;
      if (!etat.zones.any((z) => z.numero == n && z.etat != ZoneEtat.inconnue)) return false;
    }
    return true;
  }

  String formaterTexte(String texte, EtatJeu etat, {Mercenaire? mercenaire}) {
    String r = texte;
    r = r.replaceAll('{nom}',   mercenaire?.nom ?? (etat.mercenaires.isNotEmpty ? etat.mercenaires.first.nom : 'votre mercenaire'));
    r = r.replaceAll('{guilde}', etat.nomGuilde);
    return r;
  }
}

class _Ctx {
  final EtatJeu etat;
  final String? objetObtenu;
  final String? classeDebloquee;
  final String? recrueSpeciale;
  final String? zoneVaincue;
  const _Ctx({
    required this.etat,
    this.objetObtenu,
    this.classeDebloquee,
    this.recrueSpeciale,
    this.zoneVaincue,
  });
}
