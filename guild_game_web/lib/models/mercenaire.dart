// lib/models/mercenaire.dart

import 'enums.dart';
import 'classe.dart';
import 'sort.dart';

class Mercenaire {
  final String id;
  final String nom;
  
  // Stats principales (toutes à 1 au départ)
  Map<StatPrincipale, int> stats;
  
  // Substats (0 au départ, montent via postes)
  Map<Substat, int> substats;
  
  // Progression
  int niveau;
  int xp;
  int pointsStatDisponibles; // points à distribuer
  
  // HP
  int hp;
  int get hpMax => 50 + ((stats[StatPrincipale.CON] ?? 1) * 10);
  
  // Classe actuelle
  Classe classeActuelle;
  List<Classe> historiqueClasses;
  List<Sort> sortsActifs; // max 4 (1 par tier)
  
  // Statut journalier
  MercenaireSatut statut;
  String? posteAssigneId; // ID du bâtiment assigné
  bool assignationPersistante; // reste au poste les jours suivants
  
  // Blessures
  GraviteBlessure? gravite;
  int joursRestantsInfirmerie;
  int nombreFoisBlesse; // pour classes rares
  
  // Dormeur spécial
  bool formeDeReveActive;
  
  // Metadata pour classes rares
  int combatsGagnes;
  bool aJamaisEteAssigne;
  int joursConsecutifsDormis;
  
  Mercenaire({
    required this.id,
    required this.nom,
    required this.classeActuelle,
    Map<StatPrincipale, int>? stats,
    Map<Substat, int>? substats,
    this.niveau = 0,
    this.xp = 0,
    this.pointsStatDisponibles = 0,
    int? hp,
    List<Classe>? historiqueClasses,
    List<Sort>? sortsActifs,
    this.statut = MercenaireSatut.libre,
    this.posteAssigneId,
    this.assignationPersistante = false,
    this.gravite,
    this.joursRestantsInfirmerie = 0,
    this.nombreFoisBlesse = 0,
    this.formeDeReveActive = false,
    this.combatsGagnes = 0,
    this.aJamaisEteAssigne = true,
    this.joursConsecutifsDormis = 0,
  })  : stats = stats ?? {for (var s in StatPrincipale.values) s: 1},
        substats = substats ?? {},
        historiqueClasses = historiqueClasses ?? [],
        sortsActifs = sortsActifs ?? [],
        hp = hp ?? 60; // 50 + CON(1) * 10

  // ── Formules de combat ──
  int get atk => ((stats[StatPrincipale.FOR] ?? 1) * 2) +
      (stats[StatPrincipale.AGI] ?? 1) +
      (niveau * 2) + 4;

  int get atkMagique => ((stats[StatPrincipale.INT] ?? 1) * 2) +
      (niveau * 2) + 3;

  int get armure => (stats[StatPrincipale.END] ?? 1) * 2;

  int get initiative => (stats[StatPrincipale.AGI] ?? 1) +
      (stats[StatPrincipale.PER] ?? 1);

  double get chanceCritique => (stats[StatPrincipale.CHA] ?? 1) * 0.02;

  // ── Statut ──
  bool get estBlesse => statut == MercenaireSatut.blesse ||
      statut == MercenaireSatut.critique;

  bool get estDisponible => statut == MercenaireSatut.libre ||
      statut == MercenaireSatut.poste;

  bool get estCombattant => statut == MercenaireSatut.combat;

  bool get peutCombattre => !estBlesse && statut != MercenaireSatut.reve;

  // ── Substats ──
  int getSubstat(Substat s) => substats[s] ?? 0;

  void ajouterSubstat(Substat s, [int montant = 1]) {
    substats[s] = (substats[s] ?? 0) + montant;
  }

  // ── Stats ──
  void depensePointStat(StatPrincipale stat) {
    if (pointsStatDisponibles <= 0) return;
    stats[stat] = (stats[stat] ?? 1) + 1;
    pointsStatDisponibles--;
  }

  // ── Niveau ──
  void gagnerNiveau() {
    niveau++;
    xp++;
    combatsGagnes++;
    pointsStatDisponibles++;
  }

  // ── Blessures ──
  void blesser(GraviteBlessure g) {
    nombreFoisBlesse++;
    gravite = g;
    statut = g == GraviteBlessure.critique
        ? MercenaireSatut.critique
        : MercenaireSatut.blesse;

    switch (g) {
      case GraviteBlessure.legere:   joursRestantsInfirmerie = 2; break;
      case GraviteBlessure.moyenne:  joursRestantsInfirmerie = 4; break;
      case GraviteBlessure.grave:    joursRestantsInfirmerie = 8; break;
      case GraviteBlessure.critique: joursRestantsInfirmerie = 14; break;
    }
  }

  void soigner(int reductionJours) {
    joursRestantsInfirmerie =
        (joursRestantsInfirmerie - reductionJours).clamp(0, 999);
    if (joursRestantsInfirmerie <= 0) {
      statut = MercenaireSatut.libre;
      gravite = null;
      hp = (hpMax * 0.5).round();
      posteAssigneId = null;
    }
  }

  bool tickBlessure() {
    if (!estBlesse) return false;
    joursRestantsInfirmerie--;
    if (joursRestantsInfirmerie <= 0) {
      statut = MercenaireSatut.libre;
      gravite = null;
      hp = (hpMax * 0.5).round();
      return true; // guéri
    }
    return false;
  }

  // ── Classe Dormeur ──
  bool get estDormeur =>
      classeActuelle.type == ClasseType.civil &&
      getSubstat(Substat.sommeil) >= 5;

  bool get peutActiverFormeDeReve =>
      estDormeur && classeActuelle.tier.index >= ClasseTier.t3.index;

  // ── Métier civil ──
  String? get metierCivil {
    if (getSubstat(Substat.sommeil) >= 5)   return '🛏️ Dormeur';
    if (getSubstat(Substat.cuisine) >= 5)   return '👨‍🍳 Cuisinier';
    if (getSubstat(Substat.forge) >= 5)     return '🔨 Artisan';
    if (getSubstat(Substat.nature) >= 5)    return '🌿 Herboriste';
    if (getSubstat(Substat.erudition) >= 5) return '📖 Lettré';
    if (getSubstat(Substat.tactique) >= 5)  return '🛡️ Guetteur';
    if (getSubstat(Substat.entrainement) >= 5) return '🥊 Combattant';
    if (getSubstat(Substat.soin) >= 5)      return '🩹 Aide-Soignant';
    if (getSubstat(Substat.commerce) >= 5)  return '🪙 Camelot';
    return null;
  }

  // ── Copie ──
  Mercenaire copyWith({
    MercenaireSatut? statut,
    String? posteAssigneId,
    int? hp,
    int? pointsStatDisponibles,
  }) {
    return Mercenaire(
      id: id,
      nom: nom,
      classeActuelle: classeActuelle,
      stats: Map.from(stats),
      substats: Map.from(substats),
      niveau: niveau,
      xp: xp,
      pointsStatDisponibles: pointsStatDisponibles ?? this.pointsStatDisponibles,
      hp: hp ?? this.hp,
      historiqueClasses: List.from(historiqueClasses),
      sortsActifs: List.from(sortsActifs),
      statut: statut ?? this.statut,
      posteAssigneId: posteAssigneId ?? this.posteAssigneId,
      assignationPersistante: assignationPersistante,
      gravite: gravite,
      joursRestantsInfirmerie: joursRestantsInfirmerie,
      nombreFoisBlesse: nombreFoisBlesse,
      formeDeReveActive: formeDeReveActive,
      combatsGagnes: combatsGagnes,
      aJamaisEteAssigne: aJamaisEteAssigne,
      joursConsecutifsDormis: joursConsecutifsDormis,
    );
  }
}
