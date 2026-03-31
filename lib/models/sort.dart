// lib/models/sort.dart

import 'enums.dart';

class Sort {
  final String id;
  final String nom;
  final SortType type;
  final int cooldown; // 0 si passif
  final String description;
  final String emoji;
  
  // Effet calculé selon les stats du mercenaire
  final SortEffet effet;

  // Cooldown actuel en combat (mutable)
  int? cooldownActuel;

  Sort({
    required this.id,
    required this.nom,
    required this.type,
    required this.cooldown,
    required this.description,
    required this.emoji,
    required this.effet,
    this.cooldownActuel,
  });

  // Tick du cooldown — appelé à chaque tour du mercenaire
  void tickCooldown() {
    if (cooldownActuel != null && cooldownActuel! > 0) {
      cooldownActuel = cooldownActuel! - 1;
    }
  }

  bool get estDisponible => (cooldownActuel ?? 0) <= 0;
}

class SortEffet {
  // Type d'effet
  final SortEffetType typeEffet;
  
  // Formule : dégâts = statBase * multiplicateur + bonus
  final StatPrincipale? statBase;
  final double multiplicateur;
  final int bonusFixe;
  
  // Cible
  final SortCible cible;
  
  // Durée (tours)
  final int? duree;
  
  // Déclenchement automatique selon situation
  final SortDeclencheur? declencheur;

  const SortEffet({
    required this.typeEffet,
    this.statBase,
    this.multiplicateur = 1.0,
    this.bonusFixe = 0,
    this.cible = SortCible.ennemicible,
    this.duree,
    this.declencheur,
  });
}

enum SortEffetType {
  degatsPhysiques,
  degatsMagiques,
  soin,
  buff,
  debuff,
  invocation,
  controle,    // étourdissement, immobilisation
  execution,   // tue si < X% HP
  drain,       // vole des HP
  poison,      // DoT poison
  bouclier,    // absorbe des dégâts
  resurrection,
  passifDefense,
  passifAtk,
  passifInit,
}

enum SortCible {
  ennemicible,
  tousEnnemis,
  allieBlesse,
  tousAllies,
  soi,
  aleatoire,
}

enum SortDeclencheur {
  allieBasHP,        // allié < 25% HP
  ennemiBassHP,      // ennemi < 20% HP
  ennemisGroupes,    // plusieurs ennemis proches
  premierTour,       // début de combat
  ennemMage,         // ennemi lance des sorts
  seulEnCombat,      // dernier allié debout
  toujours,          // chaque tour disponible
}
