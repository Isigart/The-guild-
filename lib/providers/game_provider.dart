// lib/providers/game_provider.dart
// Gestion d'état avec Riverpod

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/etat_jeu.dart';
import '../models/enums.dart';
import '../models/mercenaire.dart';
import '../models/classe.dart';
import '../models/models.dart';
import '../systems/classe_system.dart';
import '../systems/camp_system.dart';
import '../systems/journee_system.dart';
import '../systems/progression_system.dart';
import '../systems/evenement_system.dart';
import '../systems/generateur_system.dart';
import '../systems/combat_system.dart';
import '../models/combat_models.dart';
import '../models/objet.dart';
import '../systems/objet_system.dart';
import '../models/passif_civil.dart';
import '../data/version_manager.dart';
import '../data/database.dart';

// ── Provider principal — État du jeu ──
class GameNotifier extends StateNotifier<EtatJeu?> {
  final Random _rng = Random();
  late final ClasseSystem _classeSystem;
  late final CampSystem _campSystem;
  late final ProgressionSystem _progressionSystem;
  late final EvenementSystem _evenementSystem;
  late final GenerateurSystem _generateurSystem;
  late final JourneeSystem _journeeSystem;
  late final CombatSystem _combatSystem;
  late final ObjetSystem _objetSystem;
  bool _initialise = false;

  GameNotifier() : super(null) {
    _initialiserSystèmes();
  }

  Future<void> _initialiserSystèmes() async {
    // Vérifier les versions des JSON
    final versionCheck = await VersionManager.verifierTout();
    if (!versionCheck.ok) {
      print('⚠️ Erreurs de version: \${versionCheck.erreurs}');
    }

    _generateurSystem = GenerateurSystem();
    _progressionSystem = ProgressionSystem(classeSystem: _classeSystem);
    _evenementSystem = EvenementSystem();
    _campSystem = CampSystem();
    _combatSystem = CombatSystem(
      generateurSystem: _generateurSystem,
    );
    _objetSystem = ObjetSystem();
    await _objetSystem.initialiser();

    _classeSystem = ClasseSystem();
    await _classeSystem.initialiser();

    _journeeSystem = JourneeSystem(
      classeSystem: _classeSystem,
      campSystem: _campSystem,
      evenementSystem: _evenementSystem,
      progressionSystem: _progressionSystem,
    );

    _initialise = true;
  }

  // ── Démarrer une nouvelle partie ──
  Future<void> nouvellePartie(String nomGuilde) async {
    if (!_initialise) await _initialiserSystèmes();
    final classeBase = _classeSystem.classeBase();
    final mercenaires = List.generate(
      5,
      (i) => _generateurSystem.genererMercenaire('merc_$i', classeBase),
    );

    final zones = _generateurSystem.genererZonesInitiales();

    // ── État initial de la guilde ──
    // Bureau de recrutement : seul bâtiment intact au départ
    // Les autres existent en ruines, à découvrir progressivement
    final batiments = [

      // ─ Découvert + intact ─
      Batiment(
        id: 'bureau',
        type: BatimentType.bureauDeRecrutement,
        niveau: 1,
        etat: BatimentEtat.intact,
        estDecouvert: true,
      ),

      // ─ Non découverts — en ruines (détruit = reconstruction requise) ─
      Batiment(
        id: 'dortoir',
        type: BatimentType.dortoir,
        niveau: 0,
        etat: BatimentEtat.detruit,
        estDecouvert: false,
      ),
      Batiment(
        id: 'cuisine',
        type: BatimentType.cuisine,
        niveau: 0,
        etat: BatimentEtat.detruit,
        estDecouvert: false,
      ),
      Batiment(
        id: 'forge',
        type: BatimentType.forge,
        niveau: 0,
        etat: BatimentEtat.detruit,
        estDecouvert: false,
      ),
      Batiment(
        id: 'infirmerie',
        type: BatimentType.infirmerie,
        niveau: 0,
        etat: BatimentEtat.detruit,
        estDecouvert: false,
      ),
      Batiment(
        id: 'bibliotheque',
        type: BatimentType.bibliotheque,
        niveau: 0,
        etat: BatimentEtat.detruit,
        estDecouvert: false,
      ),
      Batiment(
        id: 'taverne',
        type: BatimentType.taverne,
        niveau: 0,
        etat: BatimentEtat.endommage, // endommagé — découverte + réparation seulement
        estDecouvert: false,
      ),
      Batiment(
        id: 'tourDeGarde',
        type: BatimentType.tourDeGarde,
        niveau: 0,
        etat: BatimentEtat.detruit,
        estDecouvert: false,
      ),
      Batiment(
        id: 'terrainEntrainement',
        type: BatimentType.terrainEntrainement,
        niveau: 0,
        etat: BatimentEtat.detruit,
        estDecouvert: false,
      ),
      Batiment(
        id: 'siteDeRituel',
        type: BatimentType.siteDeRituel,
        niveau: 0,
        etat: BatimentEtat.detruit,
        estDecouvert: false,
      ),
      Batiment(
        id: 'temple',
        type: BatimentType.temple,
        niveau: 0,
        etat: BatimentEtat.detruit,
        estDecouvert: false,
      ),
      Batiment(
        id: 'lac',
        type: BatimentType.lac,
        niveau: 0,
        etat: BatimentEtat.endommage, // endommagé — juste à réparer
        estDecouvert: false,
      ),
      Batiment(
        id: 'repaireDesOmbres',
        type: BatimentType.repaireDesOmbres,
        niveau: 0,
        etat: BatimentEtat.detruit,
        estDecouvert: false,
      ),
      Batiment(
        id: 'boutique',
        type: BatimentType.boutique,
        niveau: 0,
        etat: BatimentEtat.detruit,
        estDecouvert: false,
      ),
    ];

    state = EtatJeu(
      nomGuilde: nomGuilde,
      jour: 1,
      or: 0,
      renommee: 0,
      mercenaires: mercenaires,
      batiments: batiments,
      zones: zones,
    );
  }

  // ── Améliorer un bâtiment ──
  bool ameliorerBatiment(String batimentId, int niveauActuel) {
    if (state == null) return false;
    final succes = _objetSystem.ameliorer(
      coffre: state!.coffreGuilde,
      orDisponible: state!.or,
      batimentId: batimentId,
      niveauActuel: niveauActuel,
      depenser: (or) {
        state = state!.copyWith(or: state!.or - or);
      },
    );
    if (succes) {
      // Mettre à jour le niveau du bâtiment
      final bats = state!.batiments.map((b) {
        if (b.id == batimentId) {
          b.niveau = niveauActuel + 1;
        }
        return b;
      }).toList();
      state = state!.copyWith(batiments: bats);
    }
    return succes;
  }

  // ── Info recette ──
  Map<String, int> objetsRequisPour(String batimentId, int niveau) =>
      _objetSystem.objetsRequis(batimentId, niveau, niveau + 1);

  int orRequisPour(String batimentId, int niveau) =>
      _objetSystem.orRequis(batimentId, niveau, niveau + 1);

  Map<String, int> ingredientsManquants(String batimentId, int niveau) =>
      _objetSystem.ingredientsManquantsPourAmelioration(
        coffre: state?.coffreGuilde ?? CoffreGuilde(),
        batimentId: batimentId,
        niveauActuel: niveau,
      );

  // ── Acheter un bâtiment ──
  void acheterBatiment(BatimentType type) {
    if (state == null) return;
    if (state!.or < type.cout) return;

    final nouveau = Batiment(
      id: '${type.name}_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      estDecouvert: true,
    );

    state = state!.copyWith(
      or: state!.or - type.cout,
      batiments: [...state!.batiments, nouveau],
    );
  }

  // ── Assigner mercenaire à un poste ──
  void assignerMerc(String mercId, String batimentId) {
    if (state == null) return;
    state = _campSystem.assignerMerc(state!, mercId, batimentId);
  }

  void retirerMerc(String mercId) {
    if (state == null) return;
    state = _campSystem.retirerMerc(state!, mercId);
  }

  void endommagerBatiment(String batimentId) {
    if (state == null) return;
    state = _campSystem.endommagerBatiment(state!, batimentId);
  }

  void repairerBatiment(String batimentId) {
    if (state == null) return;
    state = _campSystem.repairerBatiment(state!, batimentId);
  }

  // ── Sélectionner zone de combat ──
  void selectionnerZone(String zoneId) {
    if (state == null) return;
    state = state!.copyWith(zoneSelectionneeId: zoneId);
  }

  // ── Sélectionner équipe de combat ──
  void toggleCombattant(String mercId) {
    if (state == null) return;
    final equipe = List<String>.from(state!.equipeDeCombaIds);
    
    if (equipe.contains(mercId)) {
      equipe.remove(mercId);
      final merc = state!.mercenaires.firstWhere((m) => m.id == mercId);
      merc.statut = merc.posteAssigneId != null
          ? MercenaireSatut.poste
          : MercenaireSatut.libre;
    } else if (equipe.length < 5) {
      equipe.add(mercId);
      final merc = state!.mercenaires.firstWhere((m) => m.id == mercId);
      merc.statut = MercenaireSatut.combat;
    }
    
    state = state!.copyWith(equipeDeCombaIds: equipe);
  }

  // ── Calculer les passifs civils actifs ──
  PassifsResult calculerPassifs() {
    if (state == null) return const PassifsResult();
    final civils = state!.mercenaires
        .where((m) => !m.estBlesse && m.classeActuelle.type == ClasseType.civil)
        .map((m) => CivilPourPassif(
              estBlesse: m.estBlesse,
              passifs: m.classeActuelle.passifs ?? [],
              affinites: m.classeActuelle.affinites.map((a) => a.name).toList(),
            ))
        .toList();
    final combattantsIds = state!.equipeDeCombaIds;
    return PassifCalculateur.calculer(civils, combattantsIds);
  }

  // ── Initialiser un combat ──
  EtatCombat? initialiserCombat({bool estBoss = false}) {
    if (state == null) return null;
    final zoneId = state!.zoneSelectionneeId;
    if (zoneId == null) return null;

    final zone = state!.zones.firstWhere(
      (z) => z.numero.toString() == zoneId,
      orElse: () => state!.zones.first,
    );

    final equipe = state!.mercenaires
        .where((m) => state!.equipeDeCombaIds.contains(m.id))
        .toList();

    if (equipe.isEmpty) return null;

    final passifs = calculerPassifs();

    return _combatSystem.initialiserCombat(
      equipe: equipe,
      zone: zone,
      passifs: passifs,
      estBoss: estBoss,
      fuiteInterdite: state!.fuiteInterdite,
    );
  }

  // ── Exécuter un tick de combat ──
  EtatCombat executerTickCombat(EtatCombat etat) {
    return _combatSystem.executerTick(etat);
  }

  // ── Fuite ──
  EtatCombat fuirCombat(EtatCombat etat) {
    return _combatSystem.fuir(etat);
  }

  // ── Appliquer le résultat du combat ──
  // souZoneId : ex "1-2" ou "1-B"
  VictoireResult? appliquerResultatCombat(EtatCombat etatFinal, {String? souZoneId}) {
    if (state == null) return;
    final zoneId = state!.zoneSelectionneeId;
    if (zoneId == null) return;

    final zone = state!.zones.firstWhere(
      (z) => z.numero.toString() == zoneId,
      orElse: () => state!.zones.first,
    );

    final resultat = _combatSystem.calculerResultat(etatFinal, zone);

    // Appliquer XP aux mercenaires
    final mercs = state!.mercenaires.map((m) {
      final xp = resultat.xpParMercenaire[m.id];
      if (xp != null) {
        m.xp += xp;
        // Montée de niveau si seuil atteint
        while (m.xp >= _seuilXP(m.niveau)) {
          m.xp -= _seuilXP(m.niveau);
          m.gagnerNiveau();
        }
      }
      // Appliquer blessures
      final blessure = resultat.blessuresParMercenaire[m.id];
      if (blessure != null) m.blesser(blessure);
      return m;
    }).toList();

    // Remettre les mercenaires libres
    for (final m in mercs) {
      if (state!.equipeDeCombaIds.contains(m.id)) {
        m.statut = m.posteAssigneId != null
            ? MercenaireSatut.poste
            : MercenaireSatut.libre;
      }
    }

    // Récupérer les compagnons assommés
    for (final h in etatFinal.heroes) {
      h.compagnon?.recupererApresComabat();
    }

    // ── Progression de zone ──
    String? derniereZone;
    Set<String> souZonesCompletes = Set.from(state!.souZonesCompletes);
    if (resultat.victoire && souZoneId != null) {
      final prog = ProgressionZones.appliquerVictoire(
        etat: state!,
        souZoneId: souZoneId,
      );
      souZonesCompletes = prog.etat.souZonesCompletes;
      derniereZone = souZoneId;
    }

    // ── XP et montée de niveau ──
    final xpGagne = souZoneId != null
        ? ProgressionZones.xpPourSousZone(souZoneId)
        : 20;

    final vicResult = resultat.victoire
        ? _progressionSystem.appliquerVictoire(
            state!,
            resultat.orGagne,
            xpGagne,
            resultat.blessuresParMercenaire
                .map((k, v) => MapEntry(k, v ?? GraviteBlessure.legere))
                .where((k, v) => resultat.blessuresParMercenaire[k] != null)
                as Map<String, GraviteBlessure>,
          )
        : null;

    state = state!.copyWith(
      or: state!.or + resultat.orGagne,
      renommee: state!.renommee + resultat.renommeeGagnee,
      mercenaires: vicResult?.etat.mercenaires ?? mercs,
      equipeDeCombaIds: const [],
      zoneSelectionneeId: null,
      combatDuJourFait: true,
      souZonesCompletes: souZonesCompletes,
      derniereZoneVaincue: derniereZone,
    );
    return vicResult;
  }

  // ── Gestion équipe de combat ──
  void ajouterAEquipe(String mercId) {
    if (state == null) return;
    if (state!.equipeDeCombaIds.contains(mercId)) return;
    final equipe = List<String>.from(state!.equipeDeCombaIds)..add(mercId);
    state = state!.copyWith(equipeDeCombaIds: equipe);
  }

  void retirerDeEquipe(String mercId) {
    if (state == null) return;
    final equipe = List<String>.from(state!.equipeDeCombaIds)
        ..remove(mercId);
    state = state!.copyWith(equipeDeCombaIds: equipe);
  }

  // ── Choisir une classe après évolution ──
  void choisirClasse(String mercId, String classeId) {
    if (state == null) return;
    final merc = state!.mercenaires.firstWhere(
      (m) => m.id == mercId, orElse: () => state!.mercenaires.first);
    final classe = _classeSystem.getClasse(classeId);
    if (classe == null) return;
    _progressionSystem.promouvoir(merc, classe);
    state = state!.copyWith(mercenaires: List.from(state!.mercenaires));
  }

  // ── Zones disponibles ──
  List<String> souZonesDisponibles(int numeroZone) =>
      ProgressionZones.souZonesDisponibles(
          numeroZone, state?.souZonesCompletes ?? {});

  bool souZoneComplete(String souZoneId) =>
      state?.souZonesCompletes.contains(souZoneId) ?? false;

  int get zoneMaxDebloquee =>
      ProgressionZones.zoneMaxDebloquee(state?.souZonesCompletes ?? {});

  int _seuilXP(int niveau) => 100 + niveau * 50;

  // ── Distribuer un point de stat ──
  void distribuerStat(String mercId, StatPrincipale stat) {
    if (state == null) return;
    state = _progressionSystem.distribuerStat(state!, mercId, stat);
  }

  // ── Sélectionner les événements du jour ──
  List<Evenement> selectionnerEvenementsJour({
    String? objetObtenu,
    String? classeDebloquee,
    String? recrueSpeciale,
    String? zoneVaincue,
  }) {
    if (state == null) return [];
    return _evenementSystem.selectionnerEvenementsJour(
      state!,
      objetVientEtreObtenu: objetObtenu,
      classeVientEtreDebloquee: classeDebloquee,
      recrueVientDeRejoindre: recrueSpeciale,
      zoneVaincrueAujourdhui: zoneVaincue,
    );
  }

  // ── Appliquer le résultat d'un événement ──
  void appliquerResultatEvenement(ResultatEvenement resultat, String evenementId, {String? choixId}) {
    if (state == null) return;
    final cons = resultat.consequences;
    int orDelta = 0;

    if (cons.orGagne  != null) orDelta += cons.orGagne!;
    if (cons.orPerdu  != null) orDelta -= cons.orPerdu!;
    int renommeeDelta = 0;
    if (cons.renommeeBonus  != null) renommeeDelta += cons.renommeeBonus!;
    if (cons.renommeePerte  != null) renommeeDelta -= cons.renommeePerte!;

    // Objets gagnés → coffre
    if (cons.objetGagne != null) {
      for (final entry in cons.objetGagne!.entries) {
        final obj = _objetSystem.getObjet(entry.key);
        if (obj != null) state!.coffreGuilde.ajouter(obj, entry.value);
      }
    }

    // Substats bonus
    if (cons.substratBonus != null) {
      for (final entry in cons.substratBonus!.entries) {
        final sub = Substat.values.firstWhere(
          (s) => s.name == entry.key, orElse: () => Substat.nature);
        // Appliquer au premier mercenaire au poste concerné
        final merc = state!.mercenaires.firstWhere(
          (m) => m.posteAssigneId != null,
          orElse: () => state!.mercenaires.first,
        );
        merc.ajouterSubstat(sub, entry.value);
      }
    }

    // Stats bonus
    if (cons.statBonus != null) {
      for (final entry in cons.statBonus!.entries) {
        final stat = StatPrincipale.values.firstWhere(
          (s) => s.name == entry.key, orElse: () => StatPrincipale.FOR);
        final merc = state!.mercenaires.firstWhere(
          (m) => m.posteAssigneId != null,
          orElse: () => state!.mercenaires.first,
        );
        merc.stats[stat] = (merc.stats[stat] ?? 1) + entry.value;
      }
    }

    // Bâtiment détruit — inaccessible jusqu'à reconstruction totale
    if (cons.batimentDetruit) {
      final bats = state!.batiments.where((b) => b.estFonctionnel).toList();
      if (bats.isNotEmpty) {
        final cible = bats[_rng.nextInt(bats.length)];
        cible.etat = BatimentEtat.detruit;
        state = state!.copyWith(batiments: List.from(state!.batiments));
      }
    }
    // Bâtiment endommagé — inaccessible jusqu'aux réparations
    else if (cons.batimentEndommage) {
      final bats = state!.batiments.where((b) => b.estFonctionnel).toList();
      if (bats.isNotEmpty) {
        final cible = bats[_rng.nextInt(bats.length)];
        cible.etat = BatimentEtat.endommage;
        state = state!.copyWith(batiments: List.from(state!.batiments));
      }
    }

    // Bâtiment découvert
    if (cons.batimentDecouvert != null) {
      final type = BatimentType.values.firstWhere(
        (t) => t.name == cons.batimentDecouvert,
        orElse: () => BatimentType.bureauDeRecrutement,
      );
      decouvrirlieu(type);
    }

    // Marquer l'événement comme vu
    final vus = Set<String>.from(state!.evenementsVus)..add(evenementId);
    final choix = Map<String, String>.from(state!.choixPris);
    final jours = Map<String, int>.from(state!.jourEvenementVu);
    if (choixId != null) choix[evenementId] = choixId;
    jours[evenementId] = state!.jour;

    // Suite d'événement débloquée
    List<String> chaines = List.from(state!.chainesEnCours);
    if (cons.evenementDebloque != null) {
      chaines.add(cons.evenementDebloque!);
    }
    if (cons.chaineTerminee != null) {
      chaines.remove(cons.chaineTerminee);
    }

    state = state!.copyWith(
      or: state!.or + orDelta,
      renommee: state!.renommee + renommeeDelta,
      evenementsVus: vus,
      choixPris: choix,
      jourEvenementVu: jours,
      chainesEnCours: chaines,
    );
  }

  // ── Tous les événements (pour le journal) ──
  List<Evenement> get tousLesEvenements =>
      _evenementSystem.tousLesEvenements;

  // ── Résoudre un événement (accès public pour les popups) ──
  ResultatEvenement resoudreEvenement({
    required Evenement evenement,
    required String? choixId,
  }) {
    if (state == null) {
      return ResultatEvenement(
        evenementId: evenement.id,
        consequences: const ConsequencesEvenement(),
        texteAffiche: '',
      );
    }
    return _evenementSystem.resoudre(
      evenement: evenement,
      choixId: choixId,
      etat: state!,
    );
  }

  // ── Format texte événement ──
  String formaterTexteEvenement(String texte, {String? mercenaireId}) {
    if (state == null) return texte;
    final merc = mercenaireId != null
        ? state!.mercenaires.firstWhere((m) => m.id == mercenaireId, orElse: () => state!.mercenaires.first)
        : null;
    return _evenementSystem.formaterTexte(texte, state!, mercenaire: merc);
  }

  // ── Appliquer les drops après combat ──
  void appliquerDrops(List<EntreeCoffre> drops) {
    if (state == null) return;
    for (final drop in drops) {
      state!.coffreGuilde.ajouter(drop.objet, drop.quantite);
    }
    state = state!.copyWith(); // trigger rebuild
  }

  // ── Calculer les drops d'une sous-zone ──
  List<EntreeCoffre> calculerDropsCombat({
    required String zoneId,
    required String souZoneId,
    required bool estBoss,
  }) {
    return _objetSystem.calculerDrops(
      zoneId: zoneId,
      souZoneId: souZoneId,
      estBoss: estBoss,
    );
  }

  // ── Vendre un objet ──
  void vendreObjet(String objetId, int quantite) {
    if (state == null) return;
    final passifs = calculerPassifs();
    final multiplicateur = passifs.orCombat; // bonus commerce civil
    final or_ = _objetSystem.vendre(
      coffre: state!.coffreGuilde,
      objetId: objetId,
      quantite: quantite,
      multiplicateurCommerce: multiplicateur,
    );
    if (or_ > 0) {
      state = state!.copyWith(or: state!.or + or_);
    }
  }

  // ── Utiliser un objet comme déclencheur ──
  String? utiliserDetonateur(String objetId) {
    if (state == null) return null;
    return _objetSystem.utiliserCommeDetonateur(
      coffre: state!.coffreGuilde,
      objetId: objetId,
    );
  }

  // ── Vérifier si on peut construire ──
  bool peutConstruire(Map<String, int> recette) {
    if (state == null) return false;
    return _objetSystem.peutConstruire(
      coffre: state!.coffreGuilde,
      recette: recette,
    );
  }

  // ── Consommer pour construire ──
  bool consommerPourConstruction(Map<String, int> recette) {
    if (state == null) return false;
    return _objetSystem.consommerPourConstruction(
      coffre: state!.coffreGuilde,
      recette: recette,
    );
  }

  // ── Victoire en combat (legacy — remplacé par appliquerResultatCombat) ──
  void appliquerVictoire(int orGagne) {
    if (state == null) return;
    state = _progressionSystem.appliquerVictoire(state!, orGagne);
  }

  // ── Fin de journée ──
  Future<FinJourneeResult?> finJournee() async {
    if (state == null) return null;
    final result = await _journeeSystem.finJournee(state!);
    state = result.etat;
    return result;
  }

  Future<DebutJourneeResult?> debutJournee() async {
    if (state == null) return null;
    final result = await _journeeSystem.debutJournee(state!);
    state = result.etat;
    return result;
  }

  // ── Découvrir un bâtiment ──
  // Si le bâtiment existe déjà en ruines → juste révéler
  // Sinon → créer nouveau
  void decouvrirlieu(BatimentType type) {
    if (state == null) return;

    // Chercher si le bâtiment existe déjà non découvert
    final idx = state!.batiments.indexWhere(
      (b) => b.type == type && !b.estDecouvert,
    );

    if (idx >= 0) {
      // Révéler le bâtiment existant (en ruines)
      state!.batiments[idx].estDecouvert = true;
      state = state!.copyWith(batiments: List.from(state!.batiments));
    } else {
      // Créer un nouveau bâtiment intact (cas rare)
      final nouveau = Batiment(
        id: '${type.name}_${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        niveau: 1,
        etat: BatimentEtat.intact,
        estDecouvert: true,
      );
      state = state!.copyWith(
        batiments: [...state!.batiments, nouveau],
      );
    }
  }

  // ── Réparer un bâtiment endommagé ──
  void reparer(String batimentId) {
    if (state == null) return;
    final bat = state!.batiments.firstWhere(
      (b) => b.id == batimentId,
      orElse: () => Batiment(id: '', type: BatimentType.bureauDeRecrutement),
    );
    if (!bat.peutEtreRepare) return;
    final cout = bat.coutReparation;
    if (state!.or < cout) return;
    bat.etat = BatimentEtat.intact;
    if (bat.niveau == 0) bat.niveau = 1;
    state = state!.copyWith(
      or: state!.or - cout,
      batiments: List.from(state!.batiments),
    );
  }

  // ── Sauvegarde / Chargement ──
  Future<void> sauvegarder() async {
    if (state == null) return;
    await GameDatabase.sauvegarder(state!);
  }

  Future<bool> chargerPartie() async {
    if (!_initialise) await _initialiserSystèmes();
    final classes = _classeSystem.classes;
    final etat = await GameDatabase.charger(classes);
    if (etat == null) return false;
    state = etat;
    return true;
  }

  Future<bool> get partieExiste => GameDatabase.partieExiste();

  Future<void> supprimerPartie() async {
    await GameDatabase.supprimerPartie();
    state = null;
  }
}

// ── Providers Riverpod ──

final gameProvider = StateNotifierProvider<GameNotifier, EtatJeu?>((ref) {
  return GameNotifier();
});

// Provider dérivés pour éviter les rebuilds inutiles
final mercenairesProvider = Provider<List<Mercenaire>>((ref) {
  return ref.watch(gameProvider)?.mercenaires ?? [];
});

final orProvider = Provider<int>((ref) {
  return ref.watch(gameProvider)?.or ?? 0;
});

final jourProvider = Provider<int>((ref) {
  return ref.watch(gameProvider)?.jour ?? 1;
});

final renommeeProvider = Provider<RenommeeNiveau>((ref) {
  return ref.watch(gameProvider)?.niveauRenommee ?? RenommeeNiveau.ruines;
});

final batimentsProvider = Provider<List<Batiment>>((ref) {
  return ref.watch(gameProvider)?.batimentsDecouverts ?? [];
});

final pointsEnAttenteProvider = Provider<int>((ref) {
  return ref.watch(gameProvider)?.totalPointsEnAttente ?? 0;
});

final combatDuJourFaitProvider = Provider<bool>((ref) {
  return ref.watch(gameProvider)?.combatDuJourFait ?? false;
});
