// lib/models/passif_civil.dart
// Système complet des passifs civils — avant combat + hors combat uniquement

import 'enums.dart';

// ══════════════════════════════════════════════════════
// TYPES DE PASSIFS — catalogue officiel
// ══════════════════════════════════════════════════════

enum MomentPassif {
  horsJournee,  // s'applique entre les journées
  avantCombat,  // calculé une fois avant le début du combat
}

enum CiblePassif {
  batiment,     // améliore le bâtiment et sa progression
  utilisateurs, // améliore les mercenaires assignés au bâtiment
  combattants,  // buff les combattants avant combat
  ennemis,      // debuff les ennemis avant combat
  guilde,       // effet global sur la guilde
}

// ── Catalogue complet des modificateurs ──
// Groupés par thème pour lisibilité

// ÉCONOMIE
const String kOrCombat          = 'orCombat';          // +X% or gagné après victoire
const String kOrQuotidien       = 'orQuotidien';        // +X or par jour
const String kPrixVente         = 'prixVente';          // +X% prix de vente des items
const String kRemiseBatiments   = 'remiseBatiments';    // -X% coût des bâtiments
const String kObjetsRares       = 'objetsRares';        // +X% chance objet rare après combat

// PROGRESSION
const String kSubstratVitesse   = 'substratVitesse';    // +X% vitesse gain substat au poste
const String kSubstratBonus     = 'substratBonus';      // +N substat supplémentaire par jour
const String kNiveauBonus       = 'niveauBonus';        // +N niveaux bonus après victoire
const String kIndiceClasse      = 'indiceClasse';       // +X% chance indice classe cachée

// SOIN & BLESSURES
const String kDureeBlessures    = 'dureeBlessures';     // -X% durée des blessures
const String kGuerrisonAuto     = 'guerrisonAuto';      // guérit auto les blessures légères
const String kReduitGravite     = 'reduitGravite';      // réduit la gravité des blessures
const String kReparationBat     = 'reparationBatiments';// -X% coût réparation bâtiments

// COMBAT — BUFF COMBATTANTS (avant combat)
const String kAtk               = 'atk';               // +X% ATK physique
const String kDegatsMagiques    = 'degatsMagiques';     // +X% dégâts magiques
const String kHpMax             = 'hpMax';              // +X% HP maximum
const String kArmure            = 'armure';             // +X% réduction dégâts physiques
const String kResistanceMagique = 'resistanceMagique';  // +X% réduction dégâts magiques
const String kCritique          = 'critique';           // +X% chance critique
const String kInitiative        = 'initiative';         // +N initiative (frappe en premier)
const String kDegatsPoison      = 'degatsPoison';       // +X% dégâts de poison
const String kDegatsBonus       = 'degatsBonus';        // +X% dégâts sur faiblesses révélées

// COMBAT — BUFF SPÉCIAUX (avant combat)
const String kImmunitePoison    = 'immunitePoison';     // immunisé aux poisons
const String kImmuniePeur       = 'immunitePeur';       // immunisé à la peur/paralysie
const String kImmuniteControle  = 'immuniteControle';   // immunisé aux effets de contrôle
const String kImmuniteSuprise   = 'immuniteSuprise';    // immunisé aux embuscades
const String kImmuniteEffets    = 'immuniteEffets';     // immunisé peur + confusion
const String kImmuniteEnvout    = 'immuniteEnvoutement';// immunisé aux envoûtements
const String kResurrectionAuto  = 'resurrectionAuto';   // ressuscite auto 1 merc/combat
const String kReviveOnce        = 'reviveOnce';         // un merc survit à mort 1 fois

// COMBAT — DEBUFF ENNEMIS (avant combat)
const String kAtkEnnemis        = 'atkEnnemis';         // -X% ATK ennemis dès début
const String kStatsEnnemis      = 'statsEnnemis';       // -X% toutes stats ennemies
const String kPeurEnnemis       = 'peurEnnemis';        // X% chance paralysie peur R1
const String kEmpoisonnement    = 'empoisonnementInitial'; // ennemis empoisonnés dès R1
const String kConfusionEnnemi   = 'confusionEnnemi';    // X% ennemis s'attaquent entre eux

// COMBAT — INFORMATION (avant combat)
const String kReveleFaiblesses  = 'reveleFaiblesses';   // révèle faiblesses ennemies
const String kReveleResistances = 'reveleResistances';  // révèle résistances ennemies
const String kReveleCapa        = 'reveleCapa';         // révèle capacités spéciales
const String kReveleOrdres      = 'reveleOrdres';       // révèle pattern d'attaque
const String kSabotageInitial   = 'sabotageInitial';    // -X% stats ennemies R1 seulement

// COMBAT — SPÉCIAUX THÉMATIQUES
const String kArmeUnique        = 'armeUnique';         // forge une arme unique avant combat (+X% ATK)
const String kAdaptationArme    = 'adaptationArme';     // +X% dégâts selon le type ennemi
const String kCreaAlliee        = 'creaAlliee';         // invoque créature alliée avant combat
const String kCreaLegendaire    = 'creaLegendaire';     // invoque créature légendaire
const String kRageSacree        = 'rageSacree';         // équipe démarre en état de rage +X%
const String kEviterCombat      = 'eviterCombat';       // X% chance d'éviter le combat
const String kAnnuleCapa        = 'annuleCapa';         // annule 1 capacité spéciale ennemie
const String kEntiteAlliee      = 'entiteAlliee';       // entité occulte en soutien
const String kPrevisionBoss     = 'previsionBoss';      // révèle les capacités du boss
const String kEmpoisonnementDeg = 'degatsPoison';       // ennemis prennent X% HP de poison

// RENOMMÉE
const String kRenommeeBonus     = 'renommee';           // +X% renommée gagnée

// ══════════════════════════════════════════════════════
// MODÈLE D'UN PASSIF
// ══════════════════════════════════════════════════════

class PassifCivil {
  final String type;           // une des constantes k... ci-dessus
  final double valeur;         // valeur du modificateur
  final CiblePassif cible;
  final MomentPassif moment;
  final bool estGlobal;        // true = tous combattants, false = affinité seulement
  final String description;

  const PassifCivil({
    required this.type,
    required this.valeur,
    required this.cible,
    required this.moment,
    this.estGlobal = true,
    required this.description,
  });

  factory PassifCivil.fromJson(Map<String, dynamic> j) => PassifCivil(
    type:        j['type'],
    valeur:      (j['valeur'] as num).toDouble(),
    cible:       CiblePassif.values.firstWhere((c) => c.name == j['cible']),
    moment:      MomentPassif.values.firstWhere((m) => m.name == j['moment']),
    estGlobal:   j['estGlobal'] ?? true,
    description: j['description'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'type':        type,
    'valeur':      valeur,
    'cible':       cible.name,
    'moment':      moment.name,
    'estGlobal':   estGlobal,
    'description': description,
  };
}

// ══════════════════════════════════════════════════════
// RÉSULTAT CALCULÉ — passifs appliqués
// ══════════════════════════════════════════════════════

class PassifsResult {
  // Avant combat — combattants
  final double atk;
  final double degatsMagiques;
  final double hpMax;
  final double armure;
  final double resistanceMagique;
  final double critique;
  final double initiative;
  final double degatsBonus;
  final double degatsPoison;
  final double orCombat;

  // Avant combat — ennemis
  final double atkEnnemis;
  final double statsEnnemis;
  final double peurEnnemis;
  final double confusionEnnemi;
  final double sabotageInitial;

  // Avant combat — informations
  final bool reveleFaiblesses;
  final bool reveleResistances;
  final bool reveleCapa;
  final bool reveleOrdres;
  final bool previsionBoss;

  // Avant combat — immunités
  final bool immunitePoison;
  final bool immunitePeur;
  final bool immuniteControle;
  final bool immuniteSuprise;
  final bool immuniteEnvoutement;
  final bool immuniteEffets;

  // Avant combat — spéciaux
  final bool resurrectionAuto;
  final bool armeUnique;
  final bool rageSacree;
  final bool creaAlliee;
  final bool creaLegendaire;
  final bool entiteAlliee;
  final bool eviterCombat;
  final bool annuleCapa;
  final bool empoisonnementInitial;
  final double adaptationArme;

  // Hors journée
  final double dureeBlessures;
  final bool guerrisonAuto;
  final bool reduitGravite;
  final double substratVitesse;
  final double substratBonus;
  final double niveauBonus;
  final double orQuotidien;
  final double renommeeBonus;
  final double remiseBatiments;
  final double reparationBatiments;

  const PassifsResult({
    this.atk               = 0.0,
    this.degatsMagiques    = 0.0,
    this.hpMax             = 0.0,
    this.armure            = 0.0,
    this.resistanceMagique = 0.0,
    this.critique          = 0.0,
    this.initiative        = 0.0,
    this.degatsBonus       = 0.0,
    this.degatsPoison      = 0.0,
    this.orCombat          = 0.0,
    this.atkEnnemis        = 0.0,
    this.statsEnnemis      = 0.0,
    this.peurEnnemis       = 0.0,
    this.confusionEnnemi   = 0.0,
    this.sabotageInitial   = 0.0,
    this.reveleFaiblesses  = false,
    this.reveleResistances = false,
    this.reveleCapa        = false,
    this.reveleOrdres      = false,
    this.previsionBoss     = false,
    this.immunitePoison    = false,
    this.immunitePeur      = false,
    this.immuniteControle  = false,
    this.immuniteSuprise   = false,
    this.immuniteEnvoutement = false,
    this.immuniteEffets    = false,
    this.resurrectionAuto  = false,
    this.armeUnique        = false,
    this.rageSacree        = false,
    this.creaAlliee        = false,
    this.creaLegendaire    = false,
    this.entiteAlliee      = false,
    this.eviterCombat      = false,
    this.annuleCapa        = false,
    this.empoisonnementInitial = false,
    this.adaptationArme    = 0.0,
    this.dureeBlessures    = 0.0,
    this.guerrisonAuto     = false,
    this.reduitGravite     = false,
    this.substratVitesse   = 0.0,
    this.substratBonus     = 0.0,
    this.niveauBonus       = 0.0,
    this.orQuotidien       = 0.0,
    this.renommeeBonus     = 0.0,
    this.remiseBatiments   = 0.0,
    this.reparationBatiments = 0.0,
  });
}

// ══════════════════════════════════════════════════════
// CALCULATEUR — accumule tous les passifs actifs
// ══════════════════════════════════════════════════════

class PassifCalculateur {

  // Calcule tous les passifs actifs d'une guilde
  // Condition : civil non blessé
  static PassifsResult calculer(List<CivilPourPassif> civils, List<String> combattantsIds) {
    double atk = 0, degatsMag = 0, hpMax = 0, armure = 0, resMag = 0;
    double critique = 0, initiative = 0, degBonus = 0, degPoison = 0, orCombat = 0;
    double atkEnn = 0, statsEnn = 0, peurEnn = 0, confus = 0, sabotage = 0;
    double durBless = 0, subVit = 0, subBonus = 0, nivBonus = 0;
    double orQuot = 0, renBonus = 0, remBat = 0, repBat = 0, adaptArme = 0;

    bool reveleFaib = false, reveleRes = false, reveleCap = false;
    bool reveleOrd = false, prevBoss = false;
    bool immPoison = false, immPeur = false, immCtrl = false;
    bool immSuprise = false, immEnvout = false, immEffets = false;
    bool resurrAuto = false, armeUniq = false, rageSacr = false;
    bool creaAll = false, creaLeg = false, entiteAll = false;
    bool evitCombat = false, annulCap = false, empoisInit = false;
    bool guerAuto = false, redGrav = false;

    for (final civil in civils) {
      if (civil.estBlesse) continue; // condition : non blessé // condition d'activation

      for (final passif in civil.passifs) {
        // Vérifier affinité si pas global
        if (!passif.estGlobal) {
          final aAffinite = civil.affinites.any((aff) => combattantsIds.contains(aff));
          if (!aAffinite) continue;
        }

        final v = passif.valeur;
        switch (passif.type) {
          // Combattants — numériques
          case kAtk:               atk += v;
          case kDegatsMagiques:    degatsMag += v;
          case kHpMax:             hpMax += v;
          case kArmure:            armure += v;
          case kResistanceMagique: resMag += v;
          case kCritique:          critique += v;
          case kInitiative:        initiative += v;
          case kDegatsBonus:       degBonus += v;
          case kDegatsPoison:      degPoison += v;
          case kOrCombat:          orCombat += v;
          case kAdaptationArme:    adaptArme += v;

          // Ennemis — numériques
          case kAtkEnnemis:        atkEnn += v;
          case kStatsEnnemis:      statsEnn += v;
          case kPeurEnnemis:       peurEnn += v;
          case kConfusionEnnemi:   confus += v;
          case kSabotageInitial:   sabotage += v;

          // Hors journée — numériques
          case kDureeBlessures:    durBless += v;
          case kSubstratVitesse:   subVit += v;
          case kSubstratBonus:     subBonus += v;
          case kNiveauBonus:       nivBonus += v;
          case kOrQuotidien:       orQuot += v;
          case kRenommeeBonus:     renBonus += v;
          case kRemiseBatiments:   remBat += v;
          case kReparationBat:     repBat += v;

          // Booléens — OR logique
          case kReveleFaiblesses:  reveleFaib = true;
          case kReveleResistances: reveleRes = true;
          case kReveleCapa:        reveleCap = true;
          case kReveleOrdres:      reveleOrd = true;
          case kPrevisionBoss:     prevBoss = true;
          case kImmunitePoison:    immPoison = true;
          case kImmuniePeur:       immPeur = true;
          case kImmuniteControle:  immCtrl = true;
          case kImmuniteSuprise:   immSuprise = true;
          case kImmuniteEnvout:    immEnvout = true;
          case kImmuniteEffets:    immEffets = true;
          case kResurrectionAuto:  resurrAuto = true;
          case kArmeUnique:        armeUniq = true;
          case kRageSacree:        rageSacr = true;
          case kCreaAlliee:        creaAll = true;
          case kCreaLegendaire:    creaLeg = true;
          case kEntiteAlliee:      entiteAll = true;
          case kEviterCombat:      evitCombat = true;
          case kAnnuleCapa:        annulCap = true;
          case kEmpoisonnement:    empoisInit = true;
          case kGuerrisonAuto:     guerAuto = true;
          case kReduitGravite:     redGrav = true;
        }
      }
    }

    return PassifsResult(
      atk: atk, degatsMagiques: degatsMag, hpMax: hpMax,
      armure: armure, resistanceMagique: resMag, critique: critique,
      initiative: initiative, degatsBonus: degBonus, degatsPoison: degPoison,
      orCombat: orCombat, adaptationArme: adaptArme,
      atkEnnemis: atkEnn, statsEnnemis: statsEnn, peurEnnemis: peurEnn,
      confusionEnnemi: confus, sabotageInitial: sabotage,
      reveleFaiblesses: reveleFaib, reveleResistances: reveleRes,
      reveleCapa: reveleCap, reveleOrdres: reveleOrd, previsionBoss: prevBoss,
      immunitePoison: immPoison, immunitePeur: immPeur,
      immuniteControle: immCtrl, immuniteSuprise: immSuprise,
      immuniteEnvoutement: immEnvout, immuniteEffets: immEffets,
      resurrectionAuto: resurrAuto, armeUnique: armeUniq,
      rageSacree: rageSacr, creaAlliee: creaAll, creaLegendaire: creaLeg,
      entiteAlliee: entiteAll, eviterCombat: evitCombat,
      annuleCapa: annulCap, empoisonnementInitial: empoisInit,
      dureeBlessures: durBless, guerrisonAuto: guerAuto,
      reduitGravite: redGrav, substratVitesse: subVit,
      substratBonus: subBonus, niveauBonus: nivBonus,
      orQuotidien: orQuot, renommeeBonus: renBonus,
      remiseBatiments: remBat, reparationBatiments: repBat,
    );
  }
}

// Helper interne
class _CivilActif {  // internal
  final bool estBlesse;
  final List<PassifCivil> passifs;
  final List<String> affinites;
  const CivilPourPassif({
    required this.estBlesse,
    required this.passifs,
    required this.affinites,
  });
}


// ── Helper pour le calculateur ──
class CivilPourPassif {
  final bool estBlesse;
  final List<PassifCivil> passifs;
  final List<String> affinites;
  const CivilPourPassif({
    required this.estBlesse,
    required this.passifs,
    required this.affinites,
  });
}