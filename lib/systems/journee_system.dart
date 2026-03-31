// lib/systems/journee_system.dart
// Chef d'orchestre — boucle journalière complète

import '../models/etat_jeu.dart';
import '../models/enums.dart';
import '../models/mercenaire.dart';
import '../models/models.dart';
import '../models/classe.dart';
import 'classe_system.dart';
import 'camp_system.dart';
import 'evenement_system.dart';
import 'progression_system.dart';
import 'progression_system.dart'; // EvolutionInfo
import '../models/passif_civil.dart';

class JourneeSystem {
  final ClasseSystem classeSystem;
  final CampSystem campSystem;
  final EvenementSystem evenementSystem;
  final ProgressionSystem progressionSystem;

  JourneeSystem({
    required this.classeSystem,
    required this.campSystem,
    required this.evenementSystem,
    required this.progressionSystem,
  });

  // ══════════════════════════════════════════════════════
  // DÉBUT DE JOURNÉE
  // ══════════════════════════════════════════════════════

  Future<DebutJourneeResult> debutJournee(EtatJeu etat) async {
    var etatMaj = etat;
    final log = <String>[];

    // 1. Restaurer les assignations persistantes
    etatMaj = campSystem.restaurerAssignations(etatMaj);

    // 2. Tick blessures (réduire les jours restants)
    final tickResult = _tickBlessures(etatMaj);
    etatMaj = tickResult.etat;
    log.addAll(tickResult.messages);

    // 3. Tick buffs temporaires
    etatMaj = _tickBuffs(etatMaj);

    // 4. Vérification évolutions de classes
    final evolutions = <EvolutionInfo>[];
    for (final merc in etatMaj.mercenaires) {
      if (merc.estBlesse) continue;

      final nouvelleClasse = classeSystem.verifierEvolution(merc, etatMaj);
      if (nouvelleClasse != null) {
        progressionSystem.promouvoir(merc, nouvelleClasse);
        final notification = classeSystem.genererNotification(merc, nouvelleClasse);
        evolutions.add(EvolutionInfo(
          mercNom: merc.nom,
          ancienneClasse: merc.historiqueClasses.last,
          nouvelleClasse: nouvelleClasse,
          notification: notification,
        ));
        log.add('${merc.nom} → ${nouvelleClasse.emoji} ${nouvelleClasse.nom}');
      }
    }

    // 5. Événements fixes du jour (dortoir J15, taverne J30...)
    final evenementsFixes = evenementSystem.getEvenementsFixesJour(etatMaj.jour);
    for (final evt in evenementsFixes) {
      final evtResult = evenementSystem.appliquerEvenement(etatMaj, evt);
      etatMaj = evtResult.etat;
      if (evtResult.batimentDecouvert != null) {
        log.add('🔍 Nouveau lieu découvert !');
      }
    }

    // 6. Log du jour
    log.insert(0, '═══ JOUR ${etatMaj.jour} ═══');

    return DebutJourneeResult(
      etat: etatMaj,
      evolutions: evolutions,
      evenementsFixes: evenementsFixes,
      log: log,
    );
  }

  // ══════════════════════════════════════════════════════
  // FIN DE JOURNÉE
  // ══════════════════════════════════════════════════════

  Future<FinJourneeResult> finJournee(EtatJeu etat) async {
    var etatMaj = etat;
    final log = <String>[];

    // 1. Appliquer les substats aux mercenaires à leur poste
    etatMaj = campSystem.appliquerSubstats(etatMaj);
    log.add('📊 Substats appliquées');

    // 2. Vérifier les événements de poste
    final evenementsPoste = evenementSystem.genererEvenementsPoste(etatMaj);

    // 3. Événements aléatoires selon la Renommée
    final evenementsAleatoires = evenementSystem.genererEvenementsAleatoires(etatMaj);

    // 4. Regrouper tous les événements (limité par Renommée)
    final tousEvenements = [
      ...evenementsPoste,
      ...evenementsAleatoires,
    ].take(etatMaj.maxEvenementsParJour).toList();

    // 5. Restauration partielle des HP
    etatMaj = _restaurerHP(etatMaj);

    // 6. Passer au jour suivant
    etatMaj = etatMaj.copyWith(
      jour: etatMaj.jour + 1,
      combatDuJourFait: false,
      evenementsVusAujourdhui: [],
    );

    log.add('🌅 Jour ${etatMaj.jour} commence');

    return FinJourneeResult(
      etat: etatMaj,
      evenementsATraiter: tousEvenements,
      log: log,
    );
  }

  // ══════════════════════════════════════════════════════
  // HELPERS PRIVÉS
  // ══════════════════════════════════════════════════════

  _TickBlessuresResult _tickBlessures(EtatJeu etat) {
    final messages = <String>[];
    final reductionMedecin = _calculerReductionMedecin(etat);

    final mercsMaj = etat.mercenaires.map((m) {
      if (!m.estBlesse) return m;

      m.joursRestantsInfirmerie =
          (m.joursRestantsInfirmerie - 1 - reductionMedecin).clamp(0, 999);

      // Guérison
      if (m.joursRestantsInfirmerie <= 0) {
        m.statut = MercenaireSatut.libre;
        m.gravite = null;
        m.hp = (m.hpMax * 0.5).round();
        messages.add('🩹 ${m.nom} est rétabli et reprend du service.');
        return m;
      }

      // Aggravation si pas d'infirmerie et blessure longue
      final infirmerie = etat.getBatiment(BatimentType.infirmerie);
      final sansSoins = infirmerie == null || !infirmerie.estFonctionnel;

      if (sansSoins && m.joursRestantsInfirmerie > 10) {
        if (m.statut != MercenaireSatut.critique) {
          m.statut = MercenaireSatut.critique;
          m.gravite = GraviteBlessure.critique;
          messages.add('⚠️ ${m.nom} est en état critique ! Soignez-le rapidement.');
        }
      }

      // Risque de mort si critique 14+ jours sans soins
      if (sansSoins && m.statut == MercenaireSatut.critique &&
          m.joursRestantsInfirmerie > 14) {
        messages.add('💀 ${m.nom} est en danger de mort ! Construisez une infirmerie.');
      }

      return m;
    }).toList();

    return _TickBlessuresResult(
      etat: etat.copyWith(mercenaires: mercsMaj),
      messages: messages,
    );
  }

  int _calculerReductionMedecin(EtatJeu etat) {
    final infirmerie = etat.getBatiment(BatimentType.infirmerie);
    if (infirmerie == null || !infirmerie.estFonctionnel) return 0;

    int reduction = 0;
    for (final mercId in infirmerie.mercsAssignesIds) {
      try {
        final merc = etat.mercenaires.firstWhere((m) => m.id == mercId);
        final soin = merc.getSubstat(Substat.soin);
        if (soin >= 50) reduction += 4;
        else if (soin >= 30) reduction += 2;
        else if (soin >= 15) reduction += 1;
      } catch (_) {}
    }
    return reduction;
  }

  EtatJeu _tickBuffs(EtatJeu etat) {
    final buffsRestants = etat.buffsActifs
        .where((b) => b.joursRestants > 1)
        .map((b) => BuffTemporaire(
              id: b.id,
              description: b.description,
              modificateurs: b.modificateurs,
              joursRestants: b.joursRestants - 1,
            ))
        .toList();
    return etat.copyWith(buffsActifs: buffsRestants);
  }

  EtatJeu _restaurerHP(EtatJeu etat) {
    final mercsMaj = etat.mercenaires.map((m) {
      if (m.estBlesse) return m;
      // Récupération selon le niveau de renommée / cuisine présente
      // Passifs civils calculés via PassifCalculateur
      // Les passifs horsJournee s'appliquent ici
      final passifs = _calculerPassifsHorsJournee(etatMaj);
      final bonusCuisine = passifs.hpMax; // ex: soin HP max via cuisine
      final tauxRecup = 0.15 + bonusCuisine;
      final heal = (m.hpMax * tauxRecup).round();
      m.hp = (m.hp + heal).clamp(0, m.hpMax);
      return m;
    }).toList();
    return etat.copyWith(mercenaires: mercsMaj);
  }
}

// ═══════════════════════════════════════
// RÉSULTATS
// ═══════════════════════════════════════

class DebutJourneeResult {
  final EtatJeu etat;
  final List<EvolutionInfo> evolutions;
  final List<dynamic> evenementsFixes;
  final List<String> log;

  const DebutJourneeResult({
    required this.etat,
    required this.evolutions,
    required this.evenementsFixes,
    required this.log,
  });

  bool get aDesEvolutions => evolutions.isNotEmpty;
  bool get aDesEvenements => evenementsFixes.isNotEmpty;
}

class FinJourneeResult {
  final EtatJeu etat;
  final List<dynamic> evenementsATraiter;
  final List<String> log;

  const FinJourneeResult({
    required this.etat,
    required this.evenementsATraiter,
    required this.log,
  });

  bool get aDesEvenements => evenementsATraiter.isNotEmpty;
}

);
}

class _TickBlessuresResult {
  final EtatJeu etat;
  final List<String> messages;
  const _TickBlessuresResult({required this.etat, required this.messages});

  // ── Calculer les passifs civils hors journée ──
  PassifsResult _calculerPassifsHorsJournee(EtatJeu etat) {
    final civils = etat.mercenaires
        .where((m) => !m.estBlesse)
        .map((m) => CivilPourPassif(
              estBlesse: m.estBlesse,
              passifs: m.classeActuelle.passifs ?? [],
              affinites: m.classeActuelle.affinites.map((a) => a.name).toList(),
            ))
        .toList();
    return PassifCalculateur.calculer(civils, []);
  }
}
