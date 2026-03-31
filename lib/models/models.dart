import 'objet.dart';
// lib/models/batiment.dart

import 'enums.dart';
import 'mercenaire.dart';

class Batiment {
  final String id;
  final BatimentType type;
  int niveau; // 1, 2, 3
  BatimentEtat etat;
  bool estDecouvert;
  
  // Civils assignés
  List<String> mercsAssignesIds; // IDs des mercenaires
  
  int get slotsMax => niveau; // 1 slot par niveau
  bool get estPlein => mercsAssignesIds.length >= slotsMax;

  // Fonctionnel = découvert ET intact
  bool get estFonctionnel => etat == BatimentEtat.intact && estDecouvert;

  // Découvert mais abîmé — visible, nécessite réparation
  bool get estDecouvertMaisAbime => estDecouvert && etat != BatimentEtat.intact;

  // Existe en ruines mais pas encore trouvé
  bool get existeMaisInconnu => !estDecouvert;

  // Peut être réparé (découvert + abîmé)
  bool get peutEtreRepare => estDecouvert && etat != BatimentEtat.intact;

  int get coutReparation {
    switch (etat) {
      case BatimentEtat.endommage: return type.cout ~/ 3;
      case BatimentEtat.detruit:   return type.cout ~/ 2;
      default: return 0;
    }
  }

  int get coutReconstruction => type.cout;

  Batiment({
    required this.id,
    required this.type,
    this.niveau = 1,
    this.etat = BatimentEtat.intact,
    this.estDecouvert = false,
    List<String>? mercsAssignesIds,
  }) : mercsAssignesIds = mercsAssignesIds ?? [];

  bool assignerMerc(String mercId) {
    if (estPlein || !estFonctionnel) return false;
    if (mercsAssignesIds.contains(mercId)) return false;
    mercsAssignesIds.add(mercId);
    return true;
  }

  bool retirerMerc(String mercId) {
    return mercsAssignesIds.remove(mercId);
  }
}

// ─────────────────────────────────────────
// lib/models/ennemi.dart
// ─────────────────────────────────────────

class Ennemi {
  final String id;
  final String nom;
  final String emoji;
  final TypeEnnemi type;
  int hp;
  final int hpMax;
  final int atk;
  final int atkBase;      // valeur de base avant scaling
  final int initiative;   // position dans l'ordre d'action
  final bool estBoss;
  
  // Résistances innées (0.0 = immunisé, 1.0 = normal, 0.5 = résistant)
  final Map<String, double> resistances;

  // Loot réservé — toujours vide pour l'instant
  final List<String> tableauLoot;
  
  bool get estVivant => hp > 0;

  Ennemi({
    required this.id,
    required this.nom,
    required this.emoji,
    required this.type,
    required this.hpMax,
    required this.atk,
    int? atkBase,
    this.initiative = 5,
    this.estBoss = false,
    Map<String, double>? resistances,
    this.tableauLoot = const [],
  })  : hp = hpMax,
        atkBase = atkBase ?? atk,
        resistances = resistances ?? {};
}

// ─────────────────────────────────────────
// lib/models/zone.dart
// ─────────────────────────────────────────

class Zone {
  final int numero;
  final String nomCache;   // révélé après découverte
  final String description; // révélée après première victoire
  ZoneEtat etat;
  
  // Scaling
  final int niveauMin;
  final int niveauMax;
  
  // Composition ennemis (révélée après découverte)
  final List<TypeEnnemi> typesEnnemis;
  
  // Indices donnés par les métiers de connaissance
  String? indicePartiel;
  
  // Boss de zone
  final String? nomBoss;
  final bool aBoss;
  bool bossVaincu;
  
  // Récompenses
  final int orBase;
  final int orBonus;
  final int? difficulte;  // 1-5 — utilisé pour XP et renommée

  Zone({
    required this.numero,
    required this.nomCache,
    required this.description,
    this.etat = ZoneEtat.inconnue,
    required this.niveauMin,
    required this.niveauMax,
    required this.typesEnnemis,
    this.indicePartiel,
    this.nomBoss,
    this.aBoss = false,
    this.bossVaincu = false,
    required this.orBase,
    this.orBonus = 0,
  });

  String get nomAffiche {
    switch (etat) {
      case ZoneEtat.inconnue:   return '???';
      case ZoneEtat.mystere:    return '??? ???';
      case ZoneEtat.decouverte:
      case ZoneEtat.connue:     return nomCache;
    }
  }
}

// ─────────────────────────────────────────
// lib/models/evenement.dart
// ─────────────────────────────────────────

class Evenement {
  final String id;
  final String titre;
  final String texteNarratif;
  final EvenementType type;
  
  // Conditions de déclenchement
  final int? jourFixe;           // pour événements fixes
  final int? seuilSubstat;       // pour événements de poste
  final Substat? substratLiee;
  final RenommeeNiveau? renommeeMin;
  
  // Difficulté et résolution
  final int? seuilRequis;        // stat nécessaire pour réussir
  final StatPrincipale? statRequise;
  final Substat? substratRequise;
  
  // Conséquences
  final ConsequenceEvenement succes;
  final ConsequenceEvenement? echec; // null si pas d'échec possible
  
  // Peut revenir ?
  final bool peutRevenir;
  bool aEteVu;
  bool aEteReussi;

  Evenement({
    required this.id,
    required this.titre,
    required this.texteNarratif,
    required this.type,
    this.jourFixe,
    this.seuilSubstat,
    this.substratLiee,
    this.renommeeMin,
    this.seuilRequis,
    this.statRequise,
    this.substratRequise,
    required this.succes,
    this.echec,
    this.peutRevenir = true,
    this.aEteVu = false,
    this.aEteReussi = false,
  });

  // Calcul de l'écart pour les échecs
  int calculerEcart(int valeurActuelle) {
    if (seuilRequis == null) return 0;
    return seuilRequis! - valeurActuelle;
  }
}

class ConsequenceEvenement {
  final String texteNarratif;
  final int? orGagne;
  final int? orPerdu;
  final String? indiceClasse;       // indice sur classe cachée
  final String? batimentDecouvert;  // ID bâtiment révélé
  final Substat? substratBonus;
  final int? substratBonusMontant;
  final GraviteBlessure? blessureMerc;
  final bool? mercsBlesses;         // tous ou certains
  final String? recruiteCadeauId;   // recrue offerte
  final int? renommeeGainee;
  final Map<String, dynamic>? buffGuilde;
  final bool recrueGratuite;

  const ConsequenceEvenement({
    required this.texteNarratif,
    this.orGagne,
    this.orPerdu,
    this.indiceClasse,
    this.batimentDecouvert,
    this.substratBonus,
    this.substratBonusMontant,
    this.blessureMerc,
    this.mercsBlesses,
    this.recruiteCadeauId,
    this.renommeeGainee,
    this.buffGuilde,
    this.recrueGratuite = false,
  });
}

