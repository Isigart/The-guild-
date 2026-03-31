// lib/systems/objet_system.dart
// Système des objets — drops, chargement, vente, utilisation

import 'dart:math';
import '../models/objet.dart';
import '../data/data_loader.dart';

class ObjetSystem {
  final Random _rng = Random();

  // Cache des objets chargés depuis le JSON
  Map<String, Objet> _objets = {};
  Map<String, dynamic> _tablesDropRaw = {};
  bool _charge = false;

  // ══════════════════════════════════════════════════════
  // CHARGEMENT
  // ══════════════════════════════════════════════════════

  // Recettes de bâtiments
  Map<String, Map<String, dynamic>> _recettes = {};

  Future<void> initialiser() async {
    if (_charge) return;
    try {
      final data = await DataLoader.chargerObjets();
      final liste = data['objets'] as List<dynamic>? ?? [];
      for (final o in liste) {
        final objet = Objet.fromJson(o as Map<String, dynamic>);
        _objets[objet.id] = objet;
      }
      _tablesDropRaw = data['tables_drop'] as Map<String, dynamic>? ?? {};

      // Charger les recettes
      final recettesData = await DataLoader.chargerRecettes();
      final listeRecettes = recettesData['recettes'] as List<dynamic>? ?? [];
      for (final r in listeRecettes) {
        final rMap = r as Map<String, dynamic>;
        _recettes[rMap['id'] as String] = rMap;
      }

      _charge = true;
    } catch (e) {
      print('ObjetSystem erreur chargement: $e');
    }
  }

  Objet? getObjet(String id) => _objets[id];
  List<Objet> get tousLesObjets => _objets.values.toList();

  // ══════════════════════════════════════════════════════
  // DROPS APRÈS COMBAT
  // Scaling par zone — qualité suit la difficulté
  // ══════════════════════════════════════════════════════

  List<EntreeCoffre> calculerDrops({
    required String zoneId,      // ex: "zone_1"
    required String souZoneId,   // ex: "1-2"
    required bool estBoss,
  }) {
    final drops = <EntreeCoffre>[];
    final tableZone = _tablesDropRaw[zoneId] as Map<String, dynamic>?;
    if (tableZone == null) return drops;

    final souZones = tableZone['sous_zones'] as Map<String, dynamic>?;
    if (souZones == null) return drops;

    // Chercher la sous-zone
    final tableSZ = souZones[souZoneId] as Map<String, dynamic>?
        ?? souZones[estBoss ? '${zoneId.split('_')[1]}-B' : souZoneId] as Map<String, dynamic>?;
    if (tableSZ == null) return drops;

    // Drops garantis
    final garantis = tableSZ['garantis'] as List<dynamic>? ?? [];
    for (final g in garantis) {
      final gMap = g as Map<String, dynamic>;
      final objetId = gMap['objetId'] as String;
      final quantMin = (gMap['quantite'] as List<dynamic>)[0] as int;
      final quantMax = (gMap['quantite'] as List<dynamic>)[1] as int;
      final quantite = quantMin + _rng.nextInt(quantMax - quantMin + 1);
      final objet = _objets[objetId];
      if (objet != null && quantite > 0) {
        drops.add(EntreeCoffre(objet: objet, quantite: quantite));
      }
    }

    // Drops par chance
    final chances = tableSZ['chances'] as List<dynamic>? ?? [];
    for (final c in chances) {
      final cMap = c as Map<String, dynamic>;
      final chance = (cMap['chance'] as num).toDouble();
      if (_rng.nextDouble() <= chance) {
        final objetId = cMap['objetId'] as String;
        final quantMin = (cMap['quantite'] as List<dynamic>)[0] as int;
        final quantMax = (cMap['quantite'] as List<dynamic>)[1] as int;
        final quantite = quantMin + _rng.nextInt(quantMax - quantMin + 1);
        final objet = _objets[objetId];
        if (objet != null && quantite > 0) {
          drops.add(EntreeCoffre(objet: objet, quantite: quantite));
        }
      }
    }

    return drops;
  }

  // ══════════════════════════════════════════════════════
  // DROPS DEPUIS UN POSTE CIVIL
  // ══════════════════════════════════════════════════════

  List<EntreeCoffre> dropsPoste({
    required String typePoste,   // ex: 'forge', 'nature'
    required int niveauSubstat,  // substat du civil au poste
    required int difficulteZone, // zone actuelle débloquée
  }) {
    final drops = <EntreeCoffre>[];

    // Mapping poste → objets produits
    final produitsParPoste = <String, List<String>>{
      'forge':        ['eclat_pierre', 'minerai_commun', 'minerai_rare', 'acier_noir'],
      'nature':       ['herbe_medicinale', 'debris_bois', 'bois_robuste'],
      'occultisme':   ['vieux_parchemin', 'encre_runique', 'essence_magique'],
      'erudition':    ['vieux_parchemin', 'encre_runique'],
      'soin':         ['herbe_medicinale', 'cristal_soin'],
      'peche':        ['herbe_medicinale', 'soie_araignee'],
      'commerce':     ['lettre_recommandation', 'invitation_secrete'],
      'infiltration': ['invitation_secrete', 'carte_tresor'],
    };

    final objetsDisponibles = produitsParPoste[typePoste] ?? [];
    if (objetsDisponibles.isEmpty) return drops;

    // Qualité selon substat + zone
    final qualiteIndex = _qualiteParNiveauEtZone(niveauSubstat, difficulteZone);

    // Filtrer les objets par qualité
    final objetsFiltres = objetsDisponibles
        .map((id) => _objets[id])
        .where((o) => o != null && o!.qualite.index <= qualiteIndex)
        .cast<Objet>()
        .toList();

    if (objetsFiltres.isEmpty) return drops;

    // Drop 1 objet aléatoire parmi les disponibles
    if (_rng.nextDouble() < 0.6) { // 60% de chance de drop au poste
      final objet = objetsFiltres[_rng.nextInt(objetsFiltres.length)];
      final quantite = 1 + (niveauSubstat ~/ 20); // +1 par tranche de 20 substat
      drops.add(EntreeCoffre(objet: objet, quantite: quantite));
    }

    return drops;
  }

  int _qualiteParNiveauEtZone(int substat, int zone) {
    // commun=0, rare=1, epique=2, legendaire=3
    if (zone >= 5 && substat >= 40) return 3;
    if (zone >= 4 && substat >= 30) return 2;
    if (zone >= 2 && substat >= 15) return 1;
    return 0;
  }

  // ══════════════════════════════════════════════════════
  // VENTE D'OBJETS
  // ══════════════════════════════════════════════════════

  int calculerPrixVente(Objet objet, double multiplicateurCommerce) {
    return objet.valeurVente(multiplicateurCommerce);
  }

  // Vendre un lot d'objets — retourne l'or gagné
  int vendre({
    required CoffreGuilde coffre,
    required String objetId,
    required int quantite,
    required double multiplicateurCommerce,
  }) {
    final objet = _objets[objetId];
    if (objet == null) return 0;
    if (!coffre.retirer(objetId, quantite)) return 0;
    return calculerPrixVente(objet, multiplicateurCommerce) * quantite;
  }

  // ══════════════════════════════════════════════════════
  // VÉRIFICATION RECETTE DE CONSTRUCTION
  // ══════════════════════════════════════════════════════

  // Retourne les ingrédients manquants pour une amélioration
  Map<String, int> ingredientsManquants({
    required CoffreGuilde coffre,
    required Map<String, int> recette,
  }) {
    final manquants = <String, int>{};
    for (final entry in recette.entries) {
      final enCoffre = coffre.quantiteDe(entry.key);
      if (enCoffre < entry.value) {
        manquants[entry.key] = entry.value - enCoffre;
      }
    }
    return manquants;
  }

  bool peutConstruire({
    required CoffreGuilde coffre,
    required Map<String, int> recette,
  }) {
    return coffre.peutCrafter(recette);
  }

  // Consommer les ingrédients pour une construction
  bool consommerPourConstruction({
    required CoffreGuilde coffre,
    required Map<String, int> recette,
  }) {
    if (!peutConstruire(coffre: coffre, recette: recette)) return false;
    for (final entry in recette.entries) {
      coffre.retirer(entry.key, entry.value);
    }
    return true;
  }

  // ══════════════════════════════════════════════════════
  // DÉCLENCHEUR D'ÉVÉNEMENT
  // ══════════════════════════════════════════════════════

  // Retourne l'ID de l'événement déclenché (ou null)
  String? utiliserCommeDetonateur({
    required CoffreGuilde coffre,
    required String objetId,
  }) {
    final objet = _objets[objetId];
    if (objet == null) return null;
    if (objet.type != TypeObjet.declencheur_evenement) return null;
    if (!coffre.retirer(objetId, 1)) return null;
    return objet.evenementId;
  }

  // ══════════════════════════════════════════════════════
  // RECETTES DE BÂTIMENTS
  // ══════════════════════════════════════════════════════

  // Obtenir la recette pour une amélioration spécifique
  Map<String, dynamic>? recettePour(String batimentId, int niveauDe, int niveauVers) {
    final id = '${batimentId}_${niveauDe}_${niveauVers}';
    return _recettes[id];
  }

  // Obtenir les objets requis (Map<objetId, quantite>)
  Map<String, int> objetsRequis(String batimentId, int niveauDe, int niveauVers) {
    final recette = recettePour(batimentId, niveauDe, niveauVers);
    if (recette == null) return {};
    final objets = recette['objets'] as Map<String, dynamic>? ?? {};
    return objets.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  // Or requis
  int orRequis(String batimentId, int niveauDe, int niveauVers) {
    final recette = recettePour(batimentId, niveauDe, niveauVers);
    return (recette?['or'] as num?)?.toInt() ?? 0;
  }

  // Peut améliorer ce bâtiment ? (coffre + or)
  bool peutAmeliorer({
    required CoffreGuilde coffre,
    required int orDisponible,
    required String batimentId,
    required int niveauActuel,
  }) {
    final objets = objetsRequis(batimentId, niveauActuel, niveauActuel + 1);
    final or = orRequis(batimentId, niveauActuel, niveauActuel + 1);
    if (orDisponible < or) return false;
    return coffre.peutCrafter(objets);
  }

  // Effectuer l'amélioration — consomme or + objets
  bool ameliorer({
    required CoffreGuilde coffre,
    required int orDisponible,
    required String batimentId,
    required int niveauActuel,
    required Function(int) depenser, // callback pour dépenser l'or
  }) {
    if (!peutAmeliorer(coffre: coffre, orDisponible: orDisponible, batimentId: batimentId, niveauActuel: niveauActuel)) return false;
    final objets = objetsRequis(batimentId, niveauActuel, niveauActuel + 1);
    final or = orRequis(batimentId, niveauActuel, niveauActuel + 1);
    consommerPourConstruction(coffre: coffre, recette: objets);
    depenser(or);
    return true;
  }

  // Ingrédients manquants pour la prochaine amélioration
  Map<String, int> ingredientsManquantsPourAmelioration({
    required CoffreGuilde coffre,
    required String batimentId,
    required int niveauActuel,
  }) {
    final objets = objetsRequis(batimentId, niveauActuel, niveauActuel + 1);
    return ingredientsManquants(coffre: coffre, recette: objets);
  }

}
