// lib/models/etat_jeu.dart
// État central du jeu — source unique de vérité

import 'enums.dart';
import 'mercenaire.dart';
import 'models.dart';
import 'objet.dart';

class EtatJeu {
  // ── Guilde ──
  final String nomGuilde;
  final int jour;
  final int or;
  final int renommee;
  
  // ── Mercenaires ──
  final List<Mercenaire> mercenaires;
  
  // ── Bâtiments ──
  final List<Batiment> batiments;
  
  // ── Coffre de guilde ──
  final CoffreGuilde coffreGuilde;

  // ── Combat ──
  final List<Zone> zones;
  final Set<String> souZonesCompletes;  // ex: {"1-1", "1-2", "1-B"}
  final String? derniereZoneVaincue;    // pour événements de zone
  final List<String> equipeDeCombaIds; // IDs des 5 combattants sélectionnés
  final String? zoneSelectionneeId;    // zone choisie pour le prochain combat
  final bool fuiteInterdite;           // verrouillé par événement
  
  // ── État journalier ──
  final bool combatDuJourFait;
  final List<String> evenementsVusAujourdhui;

  // ── Historique événements ──
  final Set<String> evenementsVus;          // IDs déjà vus (persistant)
  final Map<String, String> choixPris;       // evId → choixId
  final Map<String, int> jourEvenementVu;   // evId → jour où vu
  final List<String> chainesEnCours;         // IDs de chaînes actives
  
  // ── Buffs temporaires ──
  final List<BuffTemporaire> buffsActifs;
  
  // ── Flags ──
  final bool dortoirDecouvert;
  final bool taverneDecouvert;
  final Set<String> lieuxSecretsDecouverts;

  EtatJeu({
    required this.nomGuilde,
    this.jour = 1,
    this.or = 0,
    this.renommee = 0,
    required this.mercenaires,
    required this.batiments,
    required this.zones,
    CoffreGuilde? coffreGuilde,
    this.equipeDeCombaIds = const [],
    this.zoneSelectionneeId,
    this.fuiteInterdite = false,
    Set<String>? souZonesCompletes,
    this.derniereZoneVaincue,
    this.combatDuJourFait = false,
    Set<String>? evenementsVus,
    Map<String, String>? choixPris,
    Map<String, int>? jourEvenementVu,
    this.chainesEnCours = const [],
    this.evenementsVusAujourdhui = const [],
    this.buffsActifs = const [],
    this.dortoirDecouvert = false,
    this.taverneDecouvert = false,
    Set<String>? lieuxSecretsDecouverts,
  }) : lieuxSecretsDecouverts = lieuxSecretsDecouverts ?? {},
      coffreGuilde = coffreGuilde ?? CoffreGuilde(),
      souZonesCompletes = souZonesCompletes ?? {},
      evenementsVus = evenementsVus ?? {},
      choixPris = choixPris ?? {},
      jourEvenementVu = jourEvenementVu ?? {};

  // ── Calculés ──
  RenommeeNiveau get niveauRenommee {
    for (final niveau in RenommeeNiveau.values.reversed) {
      if (renommee >= niveau.seuilRenommee) return niveau;
    }
    return RenommeeNiveau.ruines;
  }

  int get maxEvenementsParJour => niveauRenommee.maxEvenementsParJour;
  int get maxMercenaires => niveauRenommee.maxMercenaires;

  // ── Mercenaires par statut ──
  List<Mercenaire> get mercenairesLibres =>
      mercenaires.where((m) => m.statut == MercenaireSatut.libre).toList();

  List<Mercenaire> get mercenairesAuPoste =>
      mercenaires.where((m) => m.statut == MercenaireSatut.poste).toList();

  List<Mercenaire> get mercenairesEnCombat =>
      mercenaires.where((m) => m.statut == MercenaireSatut.combat).toList();

  List<Mercenaire> get mercenairesBlesses =>
      mercenaires.where((m) => m.estBlesse).toList();

  List<Mercenaire> get mercenairesDisponibles =>
      mercenaires.where((m) => m.estDisponible).toList();

  // ── Bâtiments ──
  List<Batiment> get batimentsDecouverts =>
      batiments.where((b) => b.estDecouvert).toList();

  List<Batiment> get batimentsFonctionnels =>
      batiments.where((b) => b.estFonctionnel).toList();

  Batiment? getBatiment(BatimentType type) {
    try {
      return batiments.firstWhere((b) => b.type == type);
    } catch (_) {
      return null;
    }
  }

  // ── Bonus de soutien actifs ──
  Map<String, double> get bonusSoutienActifs {
    final Map<String, double> bonus = {};
    for (final batiment in batimentsFonctionnels) {
      for (final mercId in batiment.mercsAssignesIds) {
        final merc = mercenaires.firstWhere((m) => m.id == mercId,
            orElse: () => throw Exception('Mercenaire introuvable'));
        if (merc.classeActuelle.bonusSoutien != null) {
          final b = merc.classeActuelle.bonusSoutien!;
          b.modificateurs.forEach((key, val) {
            bonus[key] = (bonus[key] ?? 0) + val;
          });
        }
      }
    }
    return bonus;
  }

  // ── Points en attente ──
  bool get aDesPointsADistribuer =>
      mercenaires.any((m) => m.pointsStatDisponibles > 0);

  int get totalPointsEnAttente =>
      mercenaires.fold(0, (sum, m) => sum + m.pointsStatDisponibles);

  // ── Actions de camp en attente ──
  bool get tousLesPostesAssignes {
    final disponibles = mercenairesDisponibles;
    return disponibles.isEmpty ||
        disponibles.every((m) => m.statut == MercenaireSatut.poste);
  }

  // ── Zones ──
  List<Zone> get zonesDecouverts =>
      zones.where((z) => z.etat != ZoneEtat.inconnue).toList();

  Zone? get prochaineZoneMysterieuse {
    try {
      return zones.firstWhere((z) =>
          z.etat == ZoneEtat.inconnue || z.etat == ZoneEtat.mystere);
    } catch (_) {
      return null;
    }
  }

  // ── copyWith ──
  EtatJeu copyWith({
    int? jour,
    int? or,
    int? renommee,
    List<Mercenaire>? mercenaires,
    List<Batiment>? batiments,
    List<Zone>? zones,
    List<String>? equipeDeCombaIds,
    bool? combatDuJourFait,
    List<String>? evenementsVusAujourdhui,
    List<BuffTemporaire>? buffsActifs,
    bool? dortoirDecouvert,
    bool? taverneDecouvert,
    Set<String>? lieuxSecretsDecouverts,
  }) {
    return EtatJeu(
      nomGuilde: nomGuilde,
      jour: jour ?? this.jour,
      or: or ?? this.or,
      renommee: renommee ?? this.renommee,
      mercenaires: mercenaires ?? this.mercenaires,
      batiments: batiments ?? this.batiments,
      zones: zones ?? this.zones,
      equipeDeCombaIds: equipeDeCombaIds ?? this.equipeDeCombaIds,
      combatDuJourFait: combatDuJourFait ?? this.combatDuJourFait,
      evenementsVusAujourdhui: evenementsVusAujourdhui ?? this.evenementsVusAujourdhui,
      buffsActifs: buffsActifs ?? this.buffsActifs,
      dortoirDecouvert: dortoirDecouvert ?? this.dortoirDecouvert,
      taverneDecouvert: taverneDecouvert ?? this.taverneDecouvert,
      lieuxSecretsDecouverts: lieuxSecretsDecouverts ?? this.lieuxSecretsDecouverts,
    );
  }
}

class BuffTemporaire {
  final String id;
  final String description;
  final Map<String, double> modificateurs;
  int joursRestants;

  BuffTemporaire({
    required this.id,
    required this.description,
    required this.modificateurs,
    required this.joursRestants,
  });
}
