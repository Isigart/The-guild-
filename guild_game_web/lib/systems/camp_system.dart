// lib/systems/camp_system.dart
// CampSystem branché à EtatJeu — assignations persistantes + substats + soutien

import '../models/etat_jeu.dart';
import '../models/mercenaire.dart';
import '../models/enums.dart';
import '../models/models.dart';
import '../models/classe.dart';

class CampSystem {

  // ══════════════════════════════════════════════════════
  // ASSIGNATIONS PERSISTANTES
  // ══════════════════════════════════════════════════════

  // Assigner un mercenaire à un bâtiment — persistant jusqu'à changement
  EtatJeu assignerMerc(EtatJeu etat, String mercId, String batimentId) {
    final merc = _getMerc(etat, mercId);
    final batiment = _getBatiment(etat, batimentId);
    if (merc == null || batiment == null) return etat;
    if (!batiment.estFonctionnel) return etat;
    if (batiment.estPlein) return etat;
    if (merc.statut == MercenaireSatut.combat) return etat; // combat prioritaire

    // Retirer de l'ancien poste si nécessaire
    var nouvelEtat = merc.posteAssigneId != null
        ? retirerMerc(etat, mercId)
        : etat;

    // Assigner au nouveau bâtiment
    final batimentsMaj = nouvelEtat.batiments.map((b) {
      if (b.id != batimentId) return b;
      b.assignerMerc(mercId);
      return b;
    }).toList();

    final mercsMaj = nouvelEtat.mercenaires.map((m) {
      if (m.id != mercId) return m;
      m.statut = MercenaireSatut.poste;
      m.posteAssigneId = batimentId;
      m.assignationPersistante = true;
      m.aJamaisEteAssigne = false;
      return m;
    }).toList();

    return nouvelEtat.copyWith(
      batiments: batimentsMaj,
      mercenaires: mercsMaj,
    );
  }

  // Retirer un mercenaire de son poste
  EtatJeu retirerMerc(EtatJeu etat, String mercId) {
    final merc = _getMerc(etat, mercId);
    if (merc?.posteAssigneId == null) return etat;

    final batimentsMaj = etat.batiments.map((b) {
      b.retirerMerc(mercId);
      return b;
    }).toList();

    final mercsMaj = etat.mercenaires.map((m) {
      if (m.id != mercId) return m;
      m.statut = MercenaireSatut.libre;
      m.posteAssigneId = null;
      m.assignationPersistante = false;
      return m;
    }).toList();

    return etat.copyWith(
      batiments: batimentsMaj,
      mercenaires: mercsMaj,
    );
  }

  // Restaurer les assignations persistantes en début de journée
  // (les assignations survivent au combat — sauf si bâtiment détruit)
  EtatJeu restaurerAssignations(EtatJeu etat) {
    final mercsMaj = etat.mercenaires.map((m) {
      // Si le mercenaire avait une assignation persistante
      if (!m.assignationPersistante || m.posteAssigneId == null) return m;

      // Vérifier que le bâtiment est encore fonctionnel
      final batiment = _getBatimentById(etat, m.posteAssigneId!);
      if (batiment == null || !batiment.estFonctionnel) {
        // Bâtiment détruit → libérer le mercenaire
        m.statut = MercenaireSatut.libre;
        m.posteAssigneId = null;
        m.assignationPersistante = false;
        return m;
      }

      // Si le mercenaire était au combat hier → retour au poste
      if (m.statut == MercenaireSatut.libre) {
        m.statut = MercenaireSatut.poste;
      }

      return m;
    }).toList();

    return etat.copyWith(mercenaires: mercsMaj);
  }

  // ══════════════════════════════════════════════════════
  // SUBSTATS — Appliquées en fin de journée
  // ══════════════════════════════════════════════════════

  EtatJeu appliquerSubstats(EtatJeu etat) {
    final resultats = <String>[]; // pour le log
    
    final mercsMaj = etat.mercenaires.map((m) {
      if (m.statut != MercenaireSatut.poste) return m;
      if (m.posteAssigneId == null) return m;

      final batiment = _getBatimentById(etat, m.posteAssigneId!);
      if (batiment == null || !batiment.estFonctionnel) return m;

      final substat = batiment.type.substat;
      if (substat == null) return m;

      // +1 substat normale
      m.ajouterSubstat(substat);

      // Cas spécial Dormeur — bonus progressif
      if (substat == Substat.sommeil) {
        m.joursConsecutifsDormis++;
        _appliquerBonusDormeur(m);
      }

      // Cas spécial Ivresse — malus avant seuil 30
      if (substat == Substat.ivresse) {
        _appliquerEffetIvresse(m);
      }

      return m;
    }).toList();

    return etat.copyWith(mercenaires: mercsMaj);
  }

  void _appliquerBonusDormeur(Mercenaire merc) {
    final sommeil = merc.getSubstat(Substat.sommeil);

    // Gains progressifs de stats selon le niveau de Sommeil
    // Note: le stat gagnée est choisie par le joueur T2+, aléatoire T1
    if (sommeil >= 77) {
      // +5 stats choisies par nuit → géré via événement spécial
      // (trop important pour être silencieux)
    } else if (sommeil >= 50) {
      // +3 stats choisies
    } else if (sommeil >= 35) {
      // +2 stats choisies
    } else if (sommeil >= 20) {
      // +1 stat choisie
    } else if (sommeil >= 10) {
      // +1 stat aléatoire (invisible pour le joueur)
      final stats = StatPrincipale.values;
      final stat = stats[sommeil % stats.length]; // pseudo-aléatoire mais deterministe
      merc.stats[stat] = (merc.stats[stat] ?? 1) + 1;
    }
    // En dessous de 10 : rien de visible
  }

  void _appliquerEffetIvresse(Mercenaire merc) {
    final ivresse = merc.getSubstat(Substat.ivresse);
    // Avant seuil 30 → malus le lendemain
    // Géré via EtatJeu.buffsActifs avec joursRestants = 1
    if (ivresse < 30) {
      // TODO: ajouter buff négatif temporaire -10% ATK
    }
  }

  // ══════════════════════════════════════════════════════
  // BONUS DE SOUTIEN — Calculés avant chaque combat
  // ══════════════════════════════════════════════════════

  BonusSoutienResult calculerBonusSoutien(
    EtatJeu etat,
    List<String> combattantsIds,
  ) {
    final bonusGlobaux = <String, double>{};
    final bonusParCombattant = <String, Map<String, double>>{};
    final descriptions = <String>[];

    // Initialiser les bonus par combattant
    for (final id in combattantsIds) {
      bonusParCombattant[id] = {};
    }

    for (final batiment in etat.batimentsFonctionnels) {
      for (final mercId in batiment.mercsAssignesIds) {
        // Le mercenaire en poste ne peut pas être au combat
        if (combattantsIds.contains(mercId)) continue;

        final merc = _getMerc(etat, mercId);
        if (merc == null) continue;

        final bonusSoutien = merc.classeActuelle.bonusSoutien;
        if (bonusSoutien == null) continue;

        if (bonusSoutien.estGlobal) {
          // Bonus pour toute l'équipe
          bonusSoutien.modificateurs.forEach((key, val) {
            bonusGlobaux[key] = (bonusGlobaux[key] ?? 0.0) + val;
          });
          descriptions.add(
            '${merc.nom} (${merc.classeActuelle.nom}) : ${bonusSoutien.description}'
          );
        } else {
          // Bonus uniquement pour les combattants ayant l'affinité
          final affinites = merc.classeActuelle.affinites;
          for (final combId in combattantsIds) {
            final combattant = _getMerc(etat, combId);
            if (combattant == null) continue;

            // Vérifier affinité : le combattant a-t-il une affinité avec ce bâtiment ?
            final aAffinite = combattant.classeActuelle.affinites
                .contains(batiment.type);

            if (aAffinite) {
              bonusSoutien.modificateurs.forEach((key, val) {
                bonusParCombattant[combId]![key] =
                    (bonusParCombattant[combId]![key] ?? 0.0) + val;
              });
            }
          }
        }
      }
    }

    return BonusSoutienResult(
      bonusGlobaux: bonusGlobaux,
      bonusParCombattant: bonusParCombattant,
      descriptions: descriptions,
    );
  }

  // ══════════════════════════════════════════════════════
  // BÂTIMENTS — Dommages et réparations
  // ══════════════════════════════════════════════════════

  EtatJeu endommagerBatiment(EtatJeu etat, String batimentId) {
    final batimentsMaj = etat.batiments.map((b) {
      if (b.id != batimentId) return b;
      b.etat = b.etat == BatimentEtat.intact
          ? BatimentEtat.endommage
          : BatimentEtat.detruit;
      return b;
    }).toList();

    // Libérer les civils si bâtiment détruit
    var nouvelEtat = etat.copyWith(batiments: batimentsMaj);
    final batiment = _getBatimentById(nouvelEtat, batimentId);
    if (batiment?.etat == BatimentEtat.detruit) {
      for (final mercId in batiment!.mercsAssignesIds) {
        nouvelEtat = retirerMerc(nouvelEtat, mercId);
      }
    }

    return nouvelEtat;
  }

  EtatJeu repairerBatiment(EtatJeu etat, String batimentId) {
    if (etat.or < _coutReparation(etat, batimentId)) return etat;

    final cout = _coutReparation(etat, batimentId);
    final batimentsMaj = etat.batiments.map((b) {
      if (b.id != batimentId) return b;
      b.etat = BatimentEtat.intact;
      return b;
    }).toList();

    return etat.copyWith(
      or: etat.or - cout,
      batiments: batimentsMaj,
    );
  }

  int _coutReparation(EtatJeu etat, String batimentId) {
    return _getBatimentById(etat, batimentId)?.coutReparation ?? 0;
  }

  // ══════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════

  Mercenaire? _getMerc(EtatJeu etat, String id) {
    try {
      return etat.mercenaires.firstWhere((m) => m.id == id);
    } catch (_) { return null; }
  }

  Batiment? _getBatiment(EtatJeu etat, String id) =>
      _getBatimentById(etat, id);

  Batiment? _getBatimentById(EtatJeu etat, String id) {
    try {
      return etat.batiments.firstWhere((b) => b.id == id);
    } catch (_) { return null; }
  }
}

// Résultat des bonus de soutien
class BonusSoutienResult {
  final Map<String, double> bonusGlobaux;
  final Map<String, Map<String, double>> bonusParCombattant;
  final List<String> descriptions;

  const BonusSoutienResult({
    required this.bonusGlobaux,
    required this.bonusParCombattant,
    required this.descriptions,
  });

  // Bonus total pour un combattant donné (global + personnel)
  Map<String, double> bonusPour(String mercId) {
    final result = Map<String, double>.from(bonusGlobaux);
    bonusParCombattant[mercId]?.forEach((key, val) {
      result[key] = (result[key] ?? 0.0) + val;
    });
    return result;
  }

  bool get aDesBonus =>
      bonusGlobaux.isNotEmpty ||
      bonusParCombattant.values.any((m) => m.isNotEmpty);
}
