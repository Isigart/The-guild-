// lib/systems/progression_system.dart
// ProgressionSystem — branche les vérifications de classes aux bons moments

import '../models/etat_jeu.dart';
import '../models/enums.dart';
import '../models/mercenaire.dart';
import '../models/classe.dart';
import '../models/sort.dart';
import '../models/models.dart';
import 'classe_system.dart';

class ProgressionSystem {
  final ClasseSystem classeSystem;

  ProgressionSystem({required this.classeSystem});

  // ══════════════════════════════════════════════════════
  // VICTOIRE EN COMBAT — niveau + vérification classes
  // ══════════════════════════════════════════════════════

  // ── Seuil XP pour monter de niveau ──
  static int seuilXP(int niveau) => 100 + (niveau * 150);

  VictoireResult appliquerVictoire(
    EtatJeu etat,
    int orGagne,
    int xpGagne,
    Map<String, GraviteBlessure> blessures,
  ) {
    final evolutions  = <EvolutionInfo>[];
    final choixClasse = <ChoixClasseInfo>[];

    final mercsMaj = etat.mercenaires.map((m) {
      if (m.statut != MercenaireSatut.combat) return m;

      // Blessures post-combat
      if (blessures.containsKey(m.id)) {
        m.blesser(blessures[m.id]!);
        return m;
      }

      // ── Gain d'XP ──
      m.xp += xpGagne;

      // ── Montée de niveau(x) ──
      while (m.xp >= seuilXP(m.niveau)) {
        m.xp -= seuilXP(m.niveau);
        m.gagnerNiveau();
      }

      // ── Vérifier évolutions de classe ──
      final classes = classeSystem.classesDisponibles(m, etat);
      if (classes.length == 1) {
        // Une seule option → automatique
        promouvoir(m, classes.first);
        evolutions.add(EvolutionInfo(
          mercId: m.id,
          mercNom: m.nom,
          nouvelleClasse: classes.first,
          notification: classeSystem.genererNotification(m, classes.first),
        ));
      } else if (classes.length > 1) {
        // Plusieurs options → joueur choisit
        choixClasse.add(ChoixClasseInfo(
          mercId: m.id,
          mercNom: m.nom,
          options: classes,
        ));
      }

      return m;
    }).toList();

    final nouvelEtat = etat.copyWith(
      or: etat.or + orGagne,
      mercenaires: mercsMaj,
      combatDuJourFait: true,
      renommee: etat.renommee + 5,
    );

    return VictoireResult(
      etat: nouvelEtat,
      orGagne: orGagne,
      evolutions: evolutions,
    );
  }

  // ══════════════════════════════════════════════════════
  // DISTRIBUER UN POINT DE STAT — vérification classe immédiate
  // ══════════════════════════════════════════════════════

  DistribuerResult distribuerStat(
    EtatJeu etat,
    String mercId,
    StatPrincipale stat,
  ) {
    EvolutionInfo? evolution;

    final mercsMaj = etat.mercenaires.map((m) {
      if (m.id != mercId) return m;

      m.depensePointStat(stat);

      // Vérifier uniquement les classes liées à cette stat
      final nouvelleClasse = classeSystem.verifierApresStatChange(m, stat, etat);
      if (nouvelleClasse != null) {
        promouvoir(m, nouvelleClasse);
        evolution = EvolutionInfo(
          mercId: m.id,
          mercNom: m.nom,
          nouvelleClasse: nouvelleClasse,
          notification: classeSystem.genererNotification(m, nouvelleClasse),
        );
      }

      return m;
    }).toList();

    return DistribuerResult(
      etat: etat.copyWith(mercenaires: mercsMaj),
      evolution: evolution,
    );
  }

  // ══════════════════════════════════════════════════════
  // APPLIQUER SUBSTAT (fin de journée) — vérification classe
  // ══════════════════════════════════════════════════════

  // Appelé par CampSystem.appliquerSubstats après chaque gain de substat
  EvolutionInfo? verifierApresSubstat(
    Mercenaire merc,
    Substat substat,
    EtatJeu etat,
  ) {
    final nouvelleClasse = classeSystem.verifierApresSubstatChange(merc, substat, etat);
    if (nouvelleClasse == null) return null;

    promouvoir(merc, nouvelleClasse);
    return EvolutionInfo(
      mercId: merc.id,
      mercNom: merc.nom,
      nouvelleClasse: nouvelleClasse,
      notification: classeSystem.genererNotification(merc, nouvelleClasse),
    );
  }

  // ══════════════════════════════════════════════════════
  // PROMOUVOIR — applique la nouvelle classe
  // ══════════════════════════════════════════════════════

  void promouvoir(Mercenaire merc, Classe nouvelleClasse) {
    merc.historiqueClasses.add(merc.classeActuelle);
    merc.classeActuelle = nouvelleClasse;

    // Ajouter le sort si pas encore au max (4 sorts)
    if (merc.sortsActifs.length < 4 &&
        !merc.sortsActifs.any((s) => s.id == nouvelleClasse.sort.id)) {
      merc.sortsActifs.add(nouvelleClasse.sort);
    }
  }

  // ══════════════════════════════════════════════════════
  // DÉFAITE — blessures
  // ══════════════════════════════════════════════════════

  EtatJeu appliquerDefaite(
    EtatJeu etat,
    Map<String, GraviteBlessure> blessures,
  ) {
    final mercsMaj = etat.mercenaires.map((m) {
      if (!blessures.containsKey(m.id)) return m;
      m.blesser(blessures[m.id]!);
      return m;
    }).toList();

    return etat.copyWith(
      mercenaires: mercsMaj,
      combatDuJourFait: true,
    );
  }
}

// ═══════════════════════════════════════
// RÉSULTATS
// ═══════════════════════════════════════

class VictoireResult {
  final EtatJeu etat;
  final int orGagne;
  final List<EvolutionInfo> evolutions;

  const VictoireResult({
    required this.etat,
    required this.orGagne,
    required this.evolutions,
  });
}

class DistribuerResult {
  final EtatJeu etat;
  final EvolutionInfo? evolution; // null si pas de nouvelle classe

  const DistribuerResult({required this.etat, this.evolution});
}

class EvolutionInfo {
  final String mercId;
  final String mercNom;
  final Classe nouvelleClasse;
  final String notification; // texte narratif sans spoiler

  const EvolutionInfo({
    required this.mercId,
    required this.mercNom,
    required this.nouvelleClasse,
    required this.notification,
  });
}
