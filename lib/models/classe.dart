// lib/models/classe.dart

import 'enums.dart';
import 'sort.dart';
import 'passif_civil.dart';

class Classe {
  final String id;
  final String nom;
  final String emoji;
  final ClasseTier tier;
  final ClasseType type;
  final String description; // texte narratif, jamais les seuils
  final Sort sort;
  
  // Prérequis
  final Map<StatPrincipale, int> reqStats;
  final Map<Substat, int> reqSubstats;
  
  // Conditions spéciales (classes rares/secrètes)
  final ConditionSpeciale? conditionSpeciale;
  
  // Bonus de soutien (civils uniquement)
  final BonusSoutien? bonusSoutien;
  
  // Affinités (pour recevoir les buffs de soutien)
  final List<BatimentType> affinites;

  // Rôle en combat (melee_physique, soigneur, etc.)
  final String? role;

  // Badge iconique affiché en combat (emoji ou chemin image)
  final String? badge;

  // Passifs civils
  final List<PassifCivil>? passifs;

  // Compagnon animal (null si aucun)
  final CompagnonData? compagnon;

  const Classe({
    required this.id,
    required this.nom,
    required this.emoji,
    required this.tier,
    required this.type,
    required this.description,
    required this.sort,
    this.reqStats = const {},
    this.reqSubstats = const {},
    this.conditionSpeciale,
    this.bonusSoutien,
    this.affinites = const [],
    this.role,
    this.badge,
    this.passifs,
    this.compagnon,
  });
}

// Condition spéciale pour classes rares
class ConditionSpeciale {
  final String description;
  final bool Function(dynamic mercenaire, dynamic etatJeu) verifier;

  const ConditionSpeciale({
    required this.description,
    required this.verifier,
  });
}

// Bonus apporté par un civil à son poste
class BonusSoutien {
  final String description;
  final Map<String, double> modificateurs; // ex: {'atk': 0.05, 'hpMax': 0.10}
  final bool estGlobal; // toute l'équipe ou affinités seulement

  const BonusSoutien({
    required this.description,
    required this.modificateurs,
    this.estGlobal = false,
  });
}


// ── Données de compagnon animal ──
class CompagnonData {
  final String nom;
  final String emoji;
  final double hpMulti;    // % HP du mercenaire
  final double atkMulti;   // % ATK du mercenaire
  final int initiative;

  const CompagnonData({
    required this.nom,
    required this.emoji,
    required this.hpMulti,
    required this.atkMulti,
    required this.initiative,
  });

  factory CompagnonData.fromJson(Map<String, dynamic> j) => CompagnonData(
    nom:        j['nom']        as String,
    emoji:      j['emoji']      as String,
    hpMulti:   (j['hpMulti']   as num).toDouble(),
    atkMulti:  (j['atkMulti']  as num).toDouble(),
    initiative:(j['initiative'] as num).toInt(),
  );
}