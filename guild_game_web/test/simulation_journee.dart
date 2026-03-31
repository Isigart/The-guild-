// test/simulation_journee.dart
// Simulation d'une journée complète — valide tous les systèmes sans UI

import 'package:guild_game/models/etat_jeu.dart';
import 'package:guild_game/models/enums.dart';
import 'package:guild_game/models/mercenaire.dart';
import 'package:guild_game/models/models.dart';
import 'package:guild_game/systems/classe_system.dart';
import 'package:guild_game/systems/camp_system.dart';
import 'package:guild_game/systems/combat_system.dart';
import 'package:guild_game/systems/evenement_system.dart';
import 'package:guild_game/systems/generateur_system.dart';
import 'package:guild_game/systems/journee_system.dart';
import 'package:guild_game/systems/progression_system.dart';

// ════════════════════════════════════════════════════════
// UTILITAIRES D'AFFICHAGE
// ════════════════════════════════════════════════════════

void log(String msg, {String prefix = ''}) =>
    print('$prefix$msg');

void separateur(String titre) {
  print('\n${'═' * 50}');
  print('  $titre');
  print('${'═' * 50}');
}

void sousSection(String titre) {
  print('\n── $titre ──');
}

void afficherMerc(Mercenaire m) {
  final stats = m.stats.entries
      .map((e) => '${e.key.shortLabel}:${e.value}')
      .join(' ');
  final subs = m.substats.entries
      .where((e) => e.value > 0)
      .map((e) => '${e.key.name}:${e.value}')
      .join(' ');

  print('  ${m.classeActuelle.emoji} ${m.nom}');
  print('    Niv.${m.niveau} | HP:${m.hp}/${m.hpMax} | Statut:${m.statut.name}');
  print('    Stats: $stats');
  if (subs.isNotEmpty) print('    Substats: $subs');
  if (m.pointsStatDisponibles > 0) print('    ⚠️  ${m.pointsStatDisponibles} point(s) à distribuer !');
  if (m.estBlesse) print('    🩸 Blessé — ${m.joursRestantsInfirmerie} jours restants');
  if (m.sortsActifs.isNotEmpty) {
    print('    Sorts: ${m.sortsActifs.map((s) => s.nom).join(', ')}');
  }
}

void afficherEtatJeu(EtatJeu etat) {
  print('\n📊 ÉTAT — Jour ${etat.jour} | Or:${etat.or} | Renommée:${etat.renommee} (${etat.niveauRenommee.label})');
  print('   Bâtiments: ${etat.batimentsDecouverts.map((b) => b.type.emoji).join('')}');
  print('   Zones découvertes: ${etat.zones.where((z) => z.etat == ZoneEtat.connue || z.etat == ZoneEtat.decouverte).length}');
}

// ════════════════════════════════════════════════════════
// INITIALISATION DU JEU
// ════════════════════════════════════════════════════════

Future<({EtatJeu etat, ClasseSystem classeSystem, CampSystem campSystem,
    CombatSystem combatSystem, EvenementSystem evenementSystem,
    GenerateurSystem generateurSystem, ProgressionSystem progressionSystem,
    JourneeSystem journeeSystem})> initialiser() async {

  separateur('INITIALISATION');

  // Systèmes
  final classeSystem = ClasseSystem();
  await classeSystem.initialiser();
  log('✓ ${classeSystem.classes.length} classes chargées');

  final generateurSystem = GenerateurSystem();
  final campSystem = CampSystem();
  final evenementSystem = EvenementSystem();
  final progressionSystem = ProgressionSystem(classeSystem: classeSystem);
  final combatSystem = CombatSystem(
    generateurSystem: generateurSystem,
    campSystem: campSystem,
  );
  final journeeSystem = JourneeSystem(
    classeSystem: classeSystem,
    campSystem: campSystem,
    evenementSystem: evenementSystem,
    progressionSystem: progressionSystem,
  );

  // État initial
  final classeBase = classeSystem.classeBase();
  final mercenaires = List.generate(5, (i) =>
      generateurSystem.genererMercenaire('merc_$i', classeBase));

  final batiments = [
    Batiment(id: 'bureau', type: BatimentType.bureauDeRecrutement, estDecouvert: true),
    Batiment(id: 'cuisine_1', type: BatimentType.cuisine, estDecouvert: true),
    Batiment(id: 'foret_1', type: BatimentType.foret, estDecouvert: true),
    Batiment(id: 'forge_1', type: BatimentType.forge, estDecouvert: true),
    Batiment(id: 'infirmerie_1', type: BatimentType.infirmerie, estDecouvert: true),
  ];

  final zones = generateurSystem.genererZonesInitiales();
  zones[0].etat = ZoneEtat.mystere; // Zone 1 visible mais mystérieuse

  var etat = EtatJeu(
    nomGuilde: 'Les Damnés du Roi',
    jour: 1,
    or: 50, // Un peu d'or pour tester les achats
    renommee: 0,
    mercenaires: mercenaires,
    batiments: batiments,
    zones: zones,
  );

  log('✓ Guilde "${etat.nomGuilde}" créée');
  log('✓ ${mercenaires.length} mercenaires générés');
  log('✓ ${batiments.length} bâtiments initiaux');

  sousSection('Mercenaires de départ');
  for (final m in etat.mercenaires) {
    afficherMerc(m);
  }

  return (
    etat: etat,
    classeSystem: classeSystem,
    campSystem: campSystem,
    combatSystem: combatSystem,
    evenementSystem: evenementSystem,
    generateurSystem: generateurSystem,
    progressionSystem: progressionSystem,
    journeeSystem: journeeSystem,
  );
}

// ════════════════════════════════════════════════════════
// SIMULATION PRINCIPALE
// ════════════════════════════════════════════════════════

Future<void> main() async {
  final sys = await initialiser();
  var etat = sys.etat;

  // ────────────────────────────────────────
  // DÉBUT DE JOURNÉE
  // ────────────────────────────────────────
  separateur('JOUR ${etat.jour} — DÉBUT');

  final debutResult = await sys.journeeSystem.debutJournee(etat);
  etat = debutResult.etat;

  for (final msg in debutResult.log) log(msg);

  if (debutResult.aDesEvolutions) {
    sousSection('Évolutions de classes');
    for (final evo in debutResult.evolutions) {
      log('  ${evo.nouvelleClasse.emoji} ${evo.mercNom} → ${evo.nouvelleClasse.nom}');
      log('  "${evo.notification}"');
    }
  }

  if (debutResult.aDesEvenements) {
    sousSection('Événements fixes du jour');
    for (final evt in debutResult.evenementsFixes) {
      log('  📜 ${evt.titre}');
      log('  ${evt.texte}');
    }
  }

  // ────────────────────────────────────────
  // ASSIGNATION DES POSTES
  // ────────────────────────────────────────
  separateur('ASSIGNATION DES POSTES');

  // merc_0 → combat (pas de poste)
  // merc_1 → cuisine
  etat = sys.campSystem.assignerMerc(etat, 'merc_1', 'cuisine_1');
  log('${etat.mercenaires[1].nom} → 🍳 Cuisine');

  // merc_2 → forêt
  etat = sys.campSystem.assignerMerc(etat, 'merc_2', 'foret_1');
  log('${etat.mercenaires[2].nom} → 🌲 Forêt');

  // merc_3 → forge
  etat = sys.campSystem.assignerMerc(etat, 'merc_3', 'forge_1');
  log('${etat.mercenaires[3].nom} → 🔨 Forge');

  // merc_4 → infirmerie
  etat = sys.campSystem.assignerMerc(etat, 'merc_4', 'infirmerie_1');
  log('${etat.mercenaires[4].nom} → 🏥 Infirmerie');

  // merc_0 → combat
  etat = etat.copyWith(equipeDeCombaIds: ['merc_0']);
  // Sélectionner tous les disponibles pour compléter l'équipe à 5
  final equipe = ['merc_0', 'merc_1', 'merc_2', 'merc_3', 'merc_4'];
  etat = etat.copyWith(equipeDeCombaIds: equipe);
  log('\n⚔️  Équipe de combat: ${equipe.map((id) => etat.mercenaires.firstWhere((m) => m.id == id).nom).join(', ')}');
  log('   (Note: tous partent au combat ce premier jour — postes vides aujourd\'hui)');

  // ────────────────────────────────────────
  // CALCUL DES BONUS DE SOUTIEN
  // ────────────────────────────────────────
  separateur('BONUS DE SOUTIEN');

  final bonusSoutien = sys.campSystem.calculerBonusSoutien(etat, equipe);
  if (bonusSoutien.aDesBonus) {
    log('Bonus globaux: ${bonusSoutien.bonusGlobaux}');
    for (final desc in bonusSoutien.descriptions) {
      log('  ✦ $desc');
    }
  } else {
    log('  Aucun civil aux postes ce tour (tous au combat)');
  }

  // ────────────────────────────────────────
  // COMBAT
  // ────────────────────────────────────────
  separateur('COMBAT — Zone 1 : ${etat.zones[0].nomAffiche}');

  final combattants = etat.mercenaires
      .where((m) => equipe.contains(m.id))
      .toList();

  var combatEtat = sys.combatSystem.initialiserCombat(
    combattants,
    etat.zones[0],
    bonusSoutien,
  );

  log('  Héros: ${combatEtat.heroes.map((h) => '${h.classeActuelle.emoji}${h.nom}(HP:${h.hp})').join(', ')}');
  log('  Ennemis: ${combatEtat.ennemis.map((e) => '${e.emoji}${e.nom}(HP:${e.hp})').join(', ')}');

  // Simuler les rounds
  int maxRounds = 20;
  while (!combatEtat.termine && maxRounds-- > 0) {
    combatEtat = sys.combatSystem.calculerRound(combatEtat);
  }

  sousSection('Log du combat');
  for (final ligne in combatEtat.log) {
    log('  $ligne');
  }

  sousSection('Résultat');
  final resultat = sys.combatSystem.calculerResultat(combatEtat, etat.zones[0]);
  log('  ${resultat.victoire ? '✦ VICTOIRE' : '💀 DÉFAITE'}');
  log('  Or gagné: ${resultat.orGagne}');
  log('  Ennemis vaincus: ${resultat.ennemisVaincus}');
  if (resultat.blessures.isNotEmpty) {
    log('  Blessures: ${resultat.blessures.entries.map((e) => '${e.key}:${e.value.name}').join(', ')}');
  }

  // Appliquer les résultats
  if (resultat.victoire) {
    final victoireResult = sys.progressionSystem.appliquerVictoire(
      etat, resultat.orGagne, resultat.blessures);
    etat = victoireResult.etat;

    // Zone découverte
    etat.zones[0].etat = ZoneEtat.decouverte;

    sousSection('Après victoire');
    log('  Or total: ${etat.or}');
    log('  Renommée: ${etat.renommee}');
    for (final m in etat.mercenaires.where((m) => m.pointsStatDisponibles > 0)) {
      log('  ⬆️  ${m.nom} Niv.${m.niveau} — ${m.pointsStatDisponibles} point(s) à distribuer');
    }

    if (victoireResult.evolutions.isNotEmpty) {
      for (final evo in victoireResult.evolutions) {
        log('  🌟 CLASSE RARE: ${evo.mercNom} → ${evo.nouvelleClasse.nom}');
      }
    }
  } else {
    etat = sys.progressionSystem.appliquerDefaite(etat, resultat.blessures);
  }

  // ────────────────────────────────────────
  // DISTRIBUTION DES POINTS DE STATS
  // ────────────────────────────────────────
  separateur('DISTRIBUTION DES POINTS DE STATS');

  for (final merc in etat.mercenaires.where((m) => m.pointsStatDisponibles > 0)) {
    // Stratégie simple : mettre dans FOR si combattant, sinon CON
    final statChoisie = merc.classeActuelle.type == ClasseType.combattant
        ? StatPrincipale.FOR
        : StatPrincipale.CON;

    final distResult = sys.progressionSystem.distribuerStat(etat, merc.id, statChoisie);
    etat = distResult.etat;

    final mercMaj = etat.mercenaires.firstWhere((m) => m.id == merc.id);
    log('  ${merc.nom} → +1 ${statChoisie.shortLabel} (maintenant: ${mercMaj.stats[statChoisie]})');

    if (distResult.evolution != null) {
      log('  🎯 NOUVELLE CLASSE: ${distResult.evolution!.mercNom} → ${distResult.evolution!.nouvelleClasse.emoji} ${distResult.evolution!.nouvelleClasse.nom}');
      log('  "${distResult.evolution!.notification}"');
    }
  }

  // ────────────────────────────────────────
  // FIN DE JOURNÉE
  // ────────────────────────────────────────
  separateur('FIN DE JOURNÉE');

  final finResult = await sys.journeeSystem.finJournee(etat);
  etat = finResult.etat;

  for (final msg in finResult.log) log(msg);

  if (finResult.aDesEvenements) {
    sousSection('Événements déclenchés');
    for (final evt in finResult.evenementsATraiter) {
      log('  📜 [${evt.type.name}] ${evt.titre}');
      log('     ${evt.texte}');

      // Résoudre l'événement
      final appResult = sys.evenementSystem.appliquerEvenement(etat, evt);
      etat = appResult.etat;

      for (final msg in appResult.messages) {
        log('     → $msg');
      }
      if (appResult.batimentDecouvert != null) {
        log('  🔍 ${appResult.batimentDecouvert!.nom} découvert !');
      }
    }
  }

  // ────────────────────────────────────────
  // BILAN FINAL
  // ────────────────────────────────────────
  separateur('BILAN — FIN DU JOUR ${etat.jour - 1}');
  afficherEtatJeu(etat);

  sousSection('État des mercenaires');
  for (final m in etat.mercenaires) {
    afficherMerc(m);
  }

  sousSection('Substats gagnées');
  for (final m in etat.mercenaires) {
    final subs = m.substats.entries.where((e) => e.value > 0);
    if (subs.isNotEmpty) {
      log('  ${m.nom}: ${subs.map((e) => '${e.key.name}:${e.value}').join(', ')}');
    }
  }

  // ────────────────────────────────────────
  // SIMULATION JOURS 2-5 (rapide)
  // ────────────────────────────────────────
  separateur('SIMULATION ACCÉLÉRÉE — JOURS 2 à 5');

  for (int j = 2; j <= 5; j++) {
    final debut = await sys.journeeSystem.debutJournee(etat);
    etat = debut.etat;

    // Restaurer les assignations persistantes (déjà fait dans debutJournee)
    // Combat rapide
    final combatants2 = etat.mercenaires.where((m) => !m.estBlesse).take(5).toList();
    if (combatants2.isNotEmpty) {
      final bonus2 = sys.campSystem.calculerBonusSoutien(
        etat, combatants2.map((m) => m.id).toList());
      var c2 = sys.combatSystem.initialiserCombat(combatants2, etat.zones[0], bonus2);
      int rounds = 0;
      while (!c2.termine && rounds++ < 20) c2 = sys.combatSystem.calculerRound(c2);

      final r2 = sys.combatSystem.calculerResultat(c2, etat.zones[0]);
      if (r2.victoire) {
        final vr = sys.progressionSystem.appliquerVictoire(etat, r2.orGagne, r2.blessures);
        etat = vr.etat;
        // Auto-distribuer FOR
        for (final m in etat.mercenaires.where((m) => m.pointsStatDisponibles > 0)) {
          final dr = sys.progressionSystem.distribuerStat(etat, m.id, StatPrincipale.FOR);
          etat = dr.etat;
          if (dr.evolution != null) {
            log('  🎯 Jour $j: ${dr.evolution!.mercNom} → ${dr.evolution!.nouvelleClasse.emoji} ${dr.evolution!.nouvelleClasse.nom}');
          }
        }
        log('  Jour $j: ✦ Victoire +${r2.orGagne}or | Or total: ${etat.or}');
      } else {
        log('  Jour $j: 💀 Défaite');
        etat = sys.progressionSystem.appliquerDefaite(etat, r2.blessures);
      }
    }

    final fin = await sys.journeeSystem.finJournee(etat);
    etat = fin.etat;
  }

  separateur('BILAN FINAL — Après 5 jours');
  afficherEtatJeu(etat);
  sousSection('Mercenaires');
  for (final m in etat.mercenaires) afficherMerc(m);

  // Vérifier les classes proches
  sousSection('Classes en approche');
  for (final m in etat.mercenaires) {
    final proches = sys.classeSystem.classesEnApproche(m, etat);
    if (proches.isNotEmpty) {
      log('  ${m.nom}:');
      for (final p in proches) {
        final pct = (p.pourcentage * 100).round();
        log('    ${p.classe.emoji} ${p.classe.nom} ($pct%) — manque: ${p.detailsManquants}');
      }
    }
  }

  print('\n✅ Simulation terminée avec succès !');
}
