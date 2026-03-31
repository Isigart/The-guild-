// lib/models/combat_models.dart
// Modèles complets du système de combat

import 'dart:math';
import 'enums.dart';
import 'mercenaire.dart';
import 'models.dart';
import 'sort.dart';

// ══════════════════════════════════════════════════════
// POSITION EN COMBAT
// ══════════════════════════════════════════════════════

enum Position { avant, milieu, arriere }

// Déduire la position depuis le rôle
Position positionDuRole(String role) {
  switch (role) {
    case 'melee_physique':
    case 'melee_magique':
    case 'protecteur':
      return Position.avant;
    case 'opportuniste':
    case 'controle':
    case 'effet_nefaste':
    case 'soutien':
      return Position.milieu;
    case 'distance_physique':
    case 'distance_magique':
    case 'soigneur':
    case 'invocateur':
    default:
      return Position.arriere;
  }
}

// ══════════════════════════════════════════════════════
// TYPES DE DÉGÂTS & RÉSISTANCES
// ══════════════════════════════════════════════════════

enum TypeDegats {
  physique, magique, feu, glace, foudre, poison,
  sacre, sombre, psychique, tranchant, contondant,
  controle, effetsNefastes, vrai, // vrai = ignore tout
}

class Resistances {
  final Map<TypeDegats, double> valeurs;

  const Resistances(this.valeurs);

  static const Resistances neutres = Resistances({});

  double get(TypeDegats type) => valeurs[type] ?? 0.0;

  // Calcul des dégâts avec résistances — plafond 0.90, minimum 1
  int calculerDegats(int degatsBase, TypeDegats type) {
    if (type == TypeDegats.vrai) return degatsBase.clamp(1, 999999);
    final r = get(type).clamp(-2.0, 0.90);
    return (degatsBase * (1.0 - r)).round().clamp(1, 999999);
  }
}

// ══════════════════════════════════════════════════════
// EFFETS DE STATUT
// ══════════════════════════════════════════════════════

enum TypeEffetStatut {
  // Altérations négatives
  poison, saignement, brulure, gel, malediction, affaiblissement,
  // Contrôles
  paralysie, confusion, charme, peur, silence, immobilisation, bannissement,
  // Buffs positifs
  rage, bouclier, concentration, haste,
  // Spéciaux
  invisibilite, marque, immunitePoison, immuniteControle,
  immuniteEffetsNefastes, immuniteMagique,
  resurrectionAuto, reviveOnce,
}

class EffetStatut {
  final TypeEffetStatut type;
  int roundsRestants;       // -1 = permanent jusqu'à dispel
  final double valeur;      // intensité (ex: 0.1 = 10% HP de poison/round)
  final String sourceId;    // qui l'a appliqué

  EffetStatut({
    required this.type,
    required this.roundsRestants,
    this.valeur = 0.0,
    required this.sourceId,
  });

  bool get estImmunite => type == TypeEffetStatut.immunitePoison ||
      type == TypeEffetStatut.immuniteControle ||
      type == TypeEffetStatut.immuniteEffetsNefastes ||
      type == TypeEffetStatut.immuniteMagique;

  bool get estControle => type == TypeEffetStatut.paralysie ||
      type == TypeEffetStatut.confusion ||
      type == TypeEffetStatut.charme ||
      type == TypeEffetStatut.peur ||
      type == TypeEffetStatut.silence ||
      type == TypeEffetStatut.immobilisation ||
      type == TypeEffetStatut.bannissement;

  bool get estAlteration => type == TypeEffetStatut.poison ||
      type == TypeEffetStatut.saignement ||
      type == TypeEffetStatut.brulure ||
      type == TypeEffetStatut.gel ||
      type == TypeEffetStatut.malediction ||
      type == TypeEffetStatut.affaiblissement;

  String get emoji {
    switch (type) {
      case TypeEffetStatut.poison:        return '☠️';
      case TypeEffetStatut.saignement:    return '🩸';
      case TypeEffetStatut.brulure:       return '🔥';
      case TypeEffetStatut.gel:           return '❄️';
      case TypeEffetStatut.malediction:   return '💀';
      case TypeEffetStatut.affaiblissement: return '⬇️';
      case TypeEffetStatut.paralysie:     return '⚡';
      case TypeEffetStatut.confusion:     return '🌀';
      case TypeEffetStatut.charme:        return '💕';
      case TypeEffetStatut.peur:          return '😱';
      case TypeEffetStatut.silence:       return '🔇';
      case TypeEffetStatut.immobilisation: return '⛓️';
      case TypeEffetStatut.bannissement:  return '🌑';
      case TypeEffetStatut.rage:          return '🔥';
      case TypeEffetStatut.bouclier:      return '🛡️';
      case TypeEffetStatut.concentration: return '🌀';
      case TypeEffetStatut.haste:         return '⚡';
      case TypeEffetStatut.invisibilite:  return '👁️';
      case TypeEffetStatut.marque:        return '🎯';
      default:                            return '✨';
    }
  }

  // Tick — retourne false si l'effet expire
  bool tick() {
    if (roundsRestants < 0) return true; // permanent
    roundsRestants--;
    return roundsRestants > 0;
  }
}

// ══════════════════════════════════════════════════════
// VISIBILITÉ
// ══════════════════════════════════════════════════════

enum EtatVisibilite { visible, invisible, revele }

// ══════════════════════════════════════════════════════
// INVOCATION
// ══════════════════════════════════════════════════════

enum TypePresence { physique, spirituel }

class Invocation {
  final String id;
  final String nom;
  final String emoji;
  final TypePresence presence;
  int hp;
  final int hpMax;
  final int atk;
  final int initiative;
  int roundsRestants;     // -1 = compagnon permanent
  bool estAssomme;        // compagnons uniquement
  final String maitreId;  // mercenaire propriétaire
  final String role;

  Invocation({
    required this.id,
    required this.nom,
    required this.emoji,
    required this.presence,
    required this.hp,
    required this.hpMax,
    required this.atk,
    required this.initiative,
    required this.roundsRestants,
    required this.maitreId,
    this.role = 'melee_physique',
    this.estAssomme = false,
  });

  bool get estPermanent => roundsRestants < 0;
  bool get estActif => !estAssomme && (estPermanent || roundsRestants > 0);
  bool get genereAgro => presence == TypePresence.physique;
  Position get position => presence == TypePresence.physique
      ? Position.avant
      : Position.arriere;

  // Après combat — compagnon récupère
  void recupererApresComabat() {
    if (estPermanent) {
      estAssomme = false;
      hp = (hpMax * 0.5).round();
    }
  }

  bool tick() {
    if (estPermanent) return true;
    roundsRestants--;
    return roundsRestants > 0;
  }
}

// ══════════════════════════════════════════════════════
// COMBATTANT EN COMBAT (wrapper mercenaire)
// ══════════════════════════════════════════════════════

class CombattantCombat {
  final Mercenaire mercenaire;
  int hpCombat;           // HP actuels en combat (séparé des HP permanents)
  int hpMaxCombat;        // HP max avec buffs passifs civils
  int atkCombat;          // ATK avec buffs
  int atkMagiqueCombat;
  int armureCombat;
  int initiativeCombat;

  final Position position;
  final String role;
  final Resistances resistances;

  // États
  List<EffetStatut> effets;
  EtatVisibilite visibilite;
  bool estAgenouille;     // HP ≤ 0 en combat
  bool aAgiBceTick;       // a déjà agi ce tick

  // Agro
  bool porteurAgro;       // cet acteur a l'agro forcé

  // Invocations actives de ce mercenaire
  List<Invocation> invocations;

  // Compagnon animal (null si aucun)
  Invocation? compagnon;

  CombattantCombat({
    required this.mercenaire,
    required this.hpCombat,
    required this.hpMaxCombat,
    required this.atkCombat,
    required this.atkMagiqueCombat,
    required this.armureCombat,
    required this.initiativeCombat,
    required this.position,
    required this.role,
    required this.resistances,
    List<EffetStatut>? effets,
    this.visibilite = EtatVisibilite.visible,
    this.estAgenouille = false,
    this.aAgiBceTick = false,
    this.porteurAgro = false,
    List<Invocation>? invocations,
    this.compagnon,
  })  : effets = effets ?? [],
        invocations = invocations ?? [];

  String get id => mercenaire.id;
  String get nom => mercenaire.nom;
  String get emoji => mercenaire.classeActuelle.emoji;
  String get badge => mercenaire.classeActuelle.badge ?? emoji;

  bool get estVivant => !estAgenouille;
  bool get estCiblable =>
      estVivant && visibilite != EtatVisibilite.invisible;

  // Vérifier si un effet est actif
  bool aEffet(TypeEffetStatut type) =>
      effets.any((e) => e.type == type && (e.roundsRestants > 0 || e.roundsRestants < 0));

  bool get estParalyse => aEffet(TypeEffetStatut.paralysie);
  bool get estConfus    => aEffet(TypeEffetStatut.confusion);
  bool get estInvisible => aEffet(TypeEffetStatut.invisibilite);
  bool get estEnRage    => aEffet(TypeEffetStatut.rage);
  bool get aBouclier    => aEffet(TypeEffetStatut.bouclier);

  double get valeurBouclier => effets
      .where((e) => e.type == TypeEffetStatut.bouclier)
      .fold(0.0, (sum, e) => sum + e.valeur);

  // Ajouter un effet (cumul si même type pour certains, remplacement pour d'autres)
  void ajouterEffet(EffetStatut effet) {
    final existant = effets.indexWhere((e) => e.type == effet.type);
    if (existant >= 0) {
      // Renouveler la durée si plus longue
      if (effet.roundsRestants > effets[existant].roundsRestants) {
        effets[existant] = effet;
      }
    } else {
      effets.add(effet);
    }
  }

  // Tick des effets — retourne les dégâts de DoT subis
  int tickEffets() {
    int degatsTotal = 0;
    effets.removeWhere((e) {
      // Calculer dégâts DoT
      if (e.type == TypeEffetStatut.poison ||
          e.type == TypeEffetStatut.saignement ||
          e.type == TypeEffetStatut.brulure) {
        final degats = (hpMaxCombat * e.valeur).round().clamp(1, 99999);
        degatsTotal += degats;
      }
      return !e.tick();
    });
    return degatsTotal;
  }

  // Recevoir des dégâts
  int recevoirDegats(int degats, TypeDegats type) {
    // Vérifier immunités
    if (type == TypeDegats.poison && aEffet(TypeEffetStatut.immunitePoison)) return 0;
    if (type == TypeDegats.controle && aEffet(TypeEffetStatut.immuniteControle)) return 0;

    // Appliquer résistances
    int degatsFinaux = resistances.calculerDegats(degats, type);

    // Bouclier d'abord
    if (aBouclier) {
      final bouclierHP = valeurBouclier.round();
      if (degatsFinaux <= bouclierHP) {
        // Le bouclier absorbe tout
        effets.removeWhere((e) => e.type == TypeEffetStatut.bouclier);
        return 0;
      }
      degatsFinaux -= bouclierHP;
      effets.removeWhere((e) => e.type == TypeEffetStatut.bouclier);
    }

    hpCombat = (hpCombat - degatsFinaux).clamp(0, hpMaxCombat);
    if (hpCombat <= 0) estAgenouille = true;
    return degatsFinaux;
  }

  // Recevoir des soins
  int recevoirSoin(int montant) {
    final avant = hpCombat;
    hpCombat = (hpCombat + montant).clamp(0, hpMaxCombat);
    return hpCombat - avant;
  }
}

// ══════════════════════════════════════════════════════
// ENNEMI EN COMBAT
// ══════════════════════════════════════════════════════

class EnnemiCombat {
  final String id;
  final String nom;
  final String emoji;
  final String role;
  final Position position;
  int hp;
  final int hpMax;
  final int atk;
  final int atkMagique;
  final int initiative;
  final Resistances resistances;

  List<EffetStatut> effets;
  EtatVisibilite visibilite;
  bool estVaincu;
  bool aAgiBceTick;

  // Capacité spéciale (annoncée un round à l'avance)
  String? capaSpecialeEnPreparation;
  int ticksAvantCapa;

  // Loot réservé pour le futur
  final List<String> tableauLoot;

  EnnemiCombat({
    required this.id,
    required this.nom,
    required this.emoji,
    required this.role,
    required this.position,
    required this.hp,
    required this.hpMax,
    required this.atk,
    this.atkMagique = 0,
    required this.initiative,
    required this.resistances,
    List<EffetStatut>? effets,
    this.visibilite = EtatVisibilite.visible,
    this.estVaincu = false,
    this.aAgiBceTick = false,
    this.capaSpecialeEnPreparation,
    this.ticksAvantCapa = 0,
    this.tableauLoot = const [],
  }) : effets = effets ?? [];

  bool get estVivant => !estVaincu && hp > 0;
  bool get estCiblable => estVivant && visibilite != EtatVisibilite.invisible;

  bool aEffet(TypeEffetStatut type) =>
      effets.any((e) => e.type == type && (e.roundsRestants > 0 || e.roundsRestants < 0));

  bool get estParalyse  => aEffet(TypeEffetStatut.paralysie);
  bool get estConfus     => aEffet(TypeEffetStatut.confusion);
  bool get estInvisible  => aEffet(TypeEffetStatut.invisibilite);

  void ajouterEffet(EffetStatut effet) {
    // Résistance au contrôle
    if (effet.estControle) {
      final resCtrl = resistances.get(TypeDegats.controle);
      if (resCtrl >= 0.90) return; // quasi-immunisé
      if (Random().nextDouble() < resCtrl) return; // résisté
    }
    final existant = effets.indexWhere((e) => e.type == effet.type);
    if (existant >= 0) {
      if (effet.roundsRestants > effets[existant].roundsRestants) {
        effets[existant] = effet;
      }
    } else {
      effets.add(effet);
    }
  }

  int tickEffets() {
    int degats = 0;
    effets.removeWhere((e) {
      if (e.type == TypeEffetStatut.poison ||
          e.type == TypeEffetStatut.saignement ||
          e.type == TypeEffetStatut.brulure) {
        degats += (hpMax * e.valeur).round().clamp(1, 99999);
      }
      return !e.tick();
    });
    return degats;
  }

  int recevoirDegats(int degats, TypeDegats type) {
    if (type == TypeDegats.poison && aEffet(TypeEffetStatut.immunitePoison)) return 0;
    final degatsFinaux = resistances.calculerDegats(degats, type);
    hp = (hp - degatsFinaux).clamp(0, hpMax);
    if (hp <= 0) estVaincu = true;
    return degatsFinaux;
  }
}

// ══════════════════════════════════════════════════════
// RÉSULTAT D'UNE ACTION
// ══════════════════════════════════════════════════════

class ActionCombat {
  final String acteurNom;
  final String acteurEmoji;
  final String? cibleNom;
  final String typeAction;  // 'attaque', 'sort', 'soin', 'effet', 'invocation'
  final int? valeur;        // dégâts ou soin
  final bool estCritique;
  final String? description;
  final String? effetApplique;

  const ActionCombat({
    required this.acteurNom,
    required this.acteurEmoji,
    this.cibleNom,
    required this.typeAction,
    this.valeur,
    this.estCritique = false,
    this.description,
    this.effetApplique,
  });

  String get texte {
    final crit = estCritique ? ' ⚡CRITIQUE!' : '';
    switch (typeAction) {
      case 'attaque':
        return '$acteurEmoji $acteurNom → $cibleNom : -$valeur HP$crit';
      case 'sort':
        return '$acteurEmoji $acteurNom → $description';
      case 'soin':
        return '$acteurEmoji $acteurNom soigne $cibleNom : +$valeur HP';
      case 'effet':
        return '$acteurEmoji $acteurNom → $effetApplique sur $cibleNom';
      case 'invocation':
        return '$acteurEmoji $acteurNom invoque $description';
      case 'dot':
        return '$acteurEmoji $acteurNom souffre de $effetApplique : -$valeur HP';
      case 'mort':
        return '💀 $acteurNom est vaincu !';
      case 'fuite':
        return '🚪 L\'équipe se replie...';
      case 'annonce':
        return '⚡ $description';
      default:
        return '$acteurEmoji $acteurNom : $description';
    }
  }
}

// ══════════════════════════════════════════════════════
// ÉTAT DU COMBAT
// ══════════════════════════════════════════════════════

class EtatCombat {
  final List<CombattantCombat> heroes;
  final List<EnnemiCombat> ennemis;
  final List<Invocation> invocationsActives; // toutes les invocations en cours

  int tick;                    // tick actuel (1 tick = 1 action)
  static const int maxTicks = 200;

  // Agro global
  String? agroForceSurId;     // ID du mercenaire avec agro forcé
  int agroRoundsRestants;

  // Résultat
  bool termine;
  bool victoire;
  bool fuite;

  // Actions du tick actuel (pour l'affichage)
  final List<ActionCombat> actionsTickActuel;

  // Historique complet (pour debug)
  final List<ActionCombat> historique;

  EtatCombat({
    required this.heroes,
    required this.ennemis,
    List<Invocation>? invocationsActives,
    this.tick = 0,
    this.agroForceSurId,
    this.agroRoundsRestants = 0,
    this.termine = false,
    this.victoire = false,
    this.fuite = false,
    List<ActionCombat>? actionsTickActuel,
    List<ActionCombat>? historique,
  })  : invocationsActives = invocationsActives ?? [],
        actionsTickActuel = actionsTickActuel ?? [],
        historique = historique ?? [];

  // Accesseurs
  List<CombattantCombat> get heroesVivants =>
      heroes.where((h) => h.estVivant).toList();
  List<EnnemiCombat> get ennemisVivants =>
      ennemis.where((e) => e.estVivant).toList();
  List<Invocation> get invocationsActives_ =>
      invocationsActives.where((i) => i.estActif).toList();

  bool get estEnCours => !termine;
  bool get tickLimiteAtteinte => tick >= maxTicks;

  // Héros ciblables selon les positions
  List<CombattantCombat> heroesCiblables(Position depuisPosition) {
    final vivants = heroesVivants.where((h) => h.estCiblable).toList();
    if (vivants.isEmpty) return [];

    // Si agro forcé — cibler ce héros en priorité
    if (agroForceSurId != null) {
      final agro = vivants.where((h) => h.id == agroForceSurId).toList();
      if (agro.isNotEmpty) return agro;
      agroForceSurId = null; // agro brisé
    }

    // Priorité de position : avant → milieu → arrière
    for (final pos in [Position.avant, Position.milieu, Position.arriere]) {
      final ligne = vivants.where((h) => h.position == pos).toList();
      // Ajouter aussi les invocations physiques en avant
      final invosAvant = invocationsActives_
          .where((i) => i.genereAgro && i.position == pos)
          .toList();
      if (ligne.isNotEmpty || invosAvant.isNotEmpty) return ligne;
    }
    return vivants;
  }

  // Ennemis ciblables selon les positions
  List<EnnemiCombat> ennemisCiblables(String roleAttaquant) {
    final vivants = ennemisVivants.where((e) => e.estCiblable).toList();
    if (vivants.isEmpty) return [];

    // Distance → peut cibler arrière directement
    if (roleAttaquant == 'distance_physique' ||
        roleAttaquant == 'distance_magique') {
      return vivants;
    }

    // Priorité de position
    for (final pos in [Position.avant, Position.milieu, Position.arriere]) {
      final ligne = vivants.where((e) => e.position == pos).toList();
      if (ligne.isNotEmpty) return ligne;
    }
    return vivants;
  }
}

// ══════════════════════════════════════════════════════
// RÉSULTAT FINAL DU COMBAT
// ══════════════════════════════════════════════════════

class ResultatCombat {
  final bool victoire;
  final bool fuite;
  final int orGagne;
  final int renommeeGagnee;
  final int ticksTotal;
  final Map<String, int> xpParMercenaire;
  final Map<String, GraviteBlessure?> blessuresParMercenaire;
  final List<String> mercenahiresMonteNiveau;
  final List<String> objetsDroppes; // réservé — toujours vide pour l'instant

  const ResultatCombat({
    required this.victoire,
    this.fuite = false,
    required this.orGagne,
    required this.renommeeGagnee,
    required this.ticksTotal,
    required this.xpParMercenaire,
    required this.blessuresParMercenaire,
    required this.mercenahiresMonteNiveau,
    this.objetsDroppes = const [],
  });
}
