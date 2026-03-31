// lib/screens/journal/journal_screen.dart
// Journal — chaînes d'événements en cours + historique

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/etat_jeu.dart';
import '../../systems/evenement_system.dart';
import '../../providers/game_provider.dart';

// ══════════════════════════════════════════════════════
// CONSTANTES
// ══════════════════════════════════════════════════════

const _or     = Color(0xFFC9A84C);
const _orDim  = Color(0xFF7A6030);
const _bg     = Color(0xFF0A0805);
const _bg2    = Color(0xFF0F0D09);
const _bg3    = Color(0xFF181510);
const _border = Color(0xFF2A2415);
const _texte  = Color(0xFFD4C49A);
const _dim    = Color(0xFF6B5A3A);

// ══════════════════════════════════════════════════════
// ÉCRAN JOURNAL
// ══════════════════════════════════════════════════════

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(gameProvider);
    if (etat == null) return const SizedBox.shrink();

    final notifier     = ref.read(gameProvider.notifier);
    final tousEvs      = notifier.tousLesEvenements;
    final evVus        = etat.evenementsVus;
    final chainesEnCours = etat.chainesEnCours;
    final choixPris    = etat.choixPris;
    final joursVus     = etat.jourEvenementVu;

    // Construire les chaînes actives
    final chainesActives = _construireChainesActives(
      etat: etat,
      tousEvs: tousEvs,
      chainesEnCours: chainesEnCours,
      evVus: evVus,
      choixPris: choixPris,
      joursVus: joursVus,
    );

    // Historique des événements vus (hors métier)
    final historique = _construireHistorique(
      tousEvs: tousEvs,
      evVus: evVus,
      joursVus: joursVus,
    );

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _JournalHeader(
            nbActives: chainesActives.length,
            nbVus: evVus.length,
          ),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  _TabBar(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Onglet 1 — Quêtes en cours
                        _OngletQuetes(
                          chaines: chainesActives,
                          jour: etat.jour,
                        ),
                        // Onglet 2 — Historique
                        _OngletHistorique(
                          historique: historique,
                          jour: etat.jour,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_ChaineInfo> _construireChainesActives({
    required EtatJeu etat,
    required List<Evenement> tousEvs,
    required List<String> chainesEnCours,
    required Set<String> evVus,
    required Map<String, String> choixPris,
    required Map<String, int> joursVus,
  }) {
    final result = <_ChaineInfo>[];

    // Pour chaque événement vu de type progression
    // chercher les suites possibles
    final progressions = tousEvs
        .where((e) => e.categorie == 'progression' &&
            evVus.contains(e.id))
        .toList();

    // Grouper par chaîne (basé sur evenementDebloque)
    final Map<String, List<Evenement>> chainesMap = {};
    for (final ev in progressions) {
      // Trouver si cet événement fait partie d'une chaîne
      final groupe = _trouverGroupeChaîne(ev.id, tousEvs);
      if (groupe != null) {
        chainesMap.putIfAbsent(groupe, () => []).add(ev);
      }
    }

    for (final entry in chainesMap.entries) {
      final evsDeChaîne = entry.value;
      final dernierVu   = evsDeChaîne.last;
      final jourDernierVu = joursVus[dernierVu.id] ?? 0;

      // Chercher la prochaine étape
      final prochainId = _trouverProchaineEtape(
          dernierVu.id, evVus, choixPris, tousEvs);
      final terminee = prochainId == null &&
          !chainesEnCours.contains(entry.key);

      result.add(_ChaineInfo(
        id:           entry.key,
        titre:        _titreChaîne(dernierVu),
        derniereEtape: dernierVu,
        resume:       _resumeEtape(dernierVu, choixPris),
        jourDernierVu: jourDernierVu,
        terminee:     terminee,
        prochainId:   prochainId,
        etapesCours:  evsDeChaîne.length,
      ));
    }

    // Trier : en cours d'abord, puis terminées
    result.sort((a, b) {
      if (a.terminee && !b.terminee) return 1;
      if (!a.terminee && b.terminee) return -1;
      return b.jourDernierVu.compareTo(a.jourDernierVu);
    });

    return result;
  }

  String? _trouverGroupeChaîne(String evId, List<Evenement> tous) {
    // Groupes de chaînes définis par leur premier événement
    const groupes = {
      'noble':          ['noble_visite', 'noble_insistance',
                         'noble_proposition', 'noble_mission',
                         'noble_recompense'],
      'forge_maudite':  ['forge_maudite_debut',
                         'forge_maudite_rituel'],
      'creature_lac':   ['creature_lac_debut',
                         'creature_lac_contact',
                         'creature_lac_retour'],
      'heritier':       ['heritier_rumeur',
                         'heritier_rencontre',
                         'heritier_document',
                         'heritier_conclusion'],
    };

    for (final entry in groupes.entries) {
      if (entry.value.contains(evId)) return entry.key;
    }
    return null;
  }

  String _titreChaîne(Evenement ev) {
    final groupe = _trouverGroupeChaîne(ev.id, []);
    switch (groupe) {
      case 'noble':         return 'Le Noble Mystérieux';
      case 'forge_maudite': return 'La Forge Maudite';
      case 'creature_lac':  return 'La Créature du Lac';
      case 'heritier':      return 'L\'Héritier Perdu';
      default:              return ev.titre;
    }
  }

  String _resumeEtape(Evenement ev,
      Map<String, String> choixPris) {
    final choixId = choixPris[ev.id];
    if (choixId == null) return ev.titre;
    final choix = ev.choix
        .where((c) => c.id == choixId)
        .firstOrNull;
    if (choix == null) return ev.titre;
    final texte = choix.consequences.texteResultat ??
        choix.consequencesSucces?.texteResultat ?? '';
    if (texte.isEmpty) return ev.titre;
    // Tronquer
    return texte.length > 80
        ? '${texte.substring(0, 77)}...'
        : texte;
  }

  String? _trouverProchaineEtape(
    String evId,
    Set<String> evVus,
    Map<String, String> choixPris,
    List<Evenement> tousEvs,
  ) {
    // Chercher un événement dont un déclencheur attend cet évId
    for (final ev in tousEvs) {
      if (evVus.contains(ev.id)) continue;
      if (ev.categorie != 'progression') continue;
      for (final d in ev.declencheurs) {
        if (d.evenementVu == evId) {
          // Vérifier le choixPris si requis
          if (d.choixPris != null &&
              choixPris[evId] != d.choixPris) continue;
          return ev.id;
        }
      }
    }
    return null;
  }

  List<_EntreeHistorique> _construireHistorique({
    required List<Evenement> tousEvs,
    required Set<String> evVus,
    required Map<String, int> joursVus,
  }) {
    return tousEvs
        .where((e) =>
            evVus.contains(e.id) &&
            e.categorie != 'metier')
        .map((e) => _EntreeHistorique(
              evenement: e,
              jour: joursVus[e.id] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.jour.compareTo(a.jour));
  }
}

// ══════════════════════════════════════════════════════
// HEADER
// ══════════════════════════════════════════════════════

class _JournalHeader extends StatelessWidget {
  final int nbActives, nbVus;
  const _JournalHeader({
    required this.nbActives, required this.nbVus,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
        16, MediaQuery.of(context).padding.top + 8, 16, 10),
    decoration: const BoxDecoration(
      color: Color(0xFF060402),
      border: Border(bottom: BorderSide(color: _border)),
    ),
    child: Row(
      children: [
        const Text('📖', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('JOURNAL',
                  style: TextStyle(
                      color: _or, fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5)),
              Text('$nbActives quête${nbActives != 1 ? 's' : ''} '
                  'en cours · $nbVus événements vécus',
                  style: const TextStyle(
                      color: _dim, fontSize: 10,
                      fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ],
    ),
  );
}

// ── TabBar ──
class _TabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: _border)),
    ),
    child: TabBar(
      labelColor: _or,
      unselectedLabelColor: _dim,
      indicatorColor: _or,
      indicatorWeight: 1.5,
      labelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2),
      tabs: const [
        Tab(text: 'QUÊTES EN COURS'),
        Tab(text: 'HISTORIQUE'),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════
// ONGLET QUÊTES EN COURS
// ══════════════════════════════════════════════════════

class _OngletQuetes extends StatelessWidget {
  final List<_ChaineInfo> chaines;
  final int jour;
  const _OngletQuetes({required this.chaines, required this.jour});

  @override
  Widget build(BuildContext context) {
    if (chaines.isEmpty) {
      return const _MessageVide(
        emoji: '📜',
        texte: 'Aucune quête en cours.',
        sous: 'Les événements de progression apparaîtront ici.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: chaines.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _CarteChaîne(
        chaine: chaines[i],
        jour: jour,
      ),
    );
  }
}

class _CarteChaîne extends StatelessWidget {
  final _ChaineInfo chaine;
  final int jour;
  const _CarteChaîne({required this.chaine, required this.jour});

  @override
  Widget build(BuildContext context) {
    final terminee = chaine.terminee;
    final couleur  = terminee
        ? const Color(0xFF27AE60)
        : _or;

    return Container(
      decoration: BoxDecoration(
        color: _bg3,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: couleur.withOpacity(0.25),
          width: terminee ? 1 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre + statut
            Row(
              children: [
                Text(terminee ? '✅' : '📖',
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(chaine.titre,
                      style: TextStyle(
                          color: couleur,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ),
                Text(
                  terminee ? 'Terminée' : 'En cours',
                  style: TextStyle(
                      color: couleur.withOpacity(0.6),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Dernier événement
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _bg2,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(chaine.derniereEtape.emoji,
                          style: const TextStyle(
                              fontSize: 14)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          chaine.derniereEtape.titre,
                          style: const TextStyle(
                              color: _texte,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text('J${chaine.jourDernierVu}',
                          style: const TextStyle(
                              color: _dim,
                              fontSize: 9)),
                    ],
                  ),
                  if (chaine.resume.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(chaine.resume,
                        style: const TextStyle(
                            color: _dim,
                            fontSize: 10,
                            height: 1.4,
                            fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),

            // Prochaine étape
            if (!terminee) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('⏳',
                      style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 6),
                  Text(
                    chaine.prochainId != null
                        ? 'La suite viendra en son temps...'
                        : 'Conditions à remplir pour continuer.',
                    style: const TextStyle(
                        color: _dim,
                        fontSize: 10,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// ONGLET HISTORIQUE
// ══════════════════════════════════════════════════════

class _OngletHistorique extends StatelessWidget {
  final List<_EntreeHistorique> historique;
  final int jour;
  const _OngletHistorique({
    required this.historique, required this.jour,
  });

  @override
  Widget build(BuildContext context) {
    if (historique.isEmpty) {
      return const _MessageVide(
        emoji: '🗺️',
        texte: 'Aucun événement vécu.',
        sous: 'L\'histoire de votre guilde s\'écrira ici.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: historique.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) => _LigneHistorique(
        entree: historique[i],
      ),
    );
  }
}

class _LigneHistorique extends StatelessWidget {
  final _EntreeHistorique entree;
  const _LigneHistorique({required this.entree});

  Color get _couleurCat {
    switch (entree.evenement.categorie) {
      case 'progression': return _or;
      case 'aleatoire':   return _texte;
      default:            return _dim;
    }
  }

  String get _labelCat {
    switch (entree.evenement.categorie) {
      case 'progression': return '📖';
      case 'aleatoire':   return '🎲';
      default:            return '📜';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _bg3,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Text(entree.evenement.emoji,
              style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entree.evenement.titre,
                    style: TextStyle(
                        color: _couleurCat,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                Text(_labelCat,
                    style: const TextStyle(
                        color: _dim, fontSize: 9)),
              ],
            ),
          ),
          Text('J${entree.jour}',
              style: const TextStyle(
                  color: _dim, fontSize: 10)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// MESSAGE VIDE
// ══════════════════════════════════════════════════════

class _MessageVide extends StatelessWidget {
  final String emoji, texte, sous;
  const _MessageVide({
    required this.emoji,
    required this.texte,
    required this.sous,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji,
            style: const TextStyle(fontSize: 36)),
        const SizedBox(height: 12),
        Text(texte,
            style: const TextStyle(
                color: _dim, fontSize: 13,
                fontStyle: FontStyle.italic)),
        const SizedBox(height: 4),
        Text(sous,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: _dim, fontSize: 10)),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════
// DATA CLASSES
// ══════════════════════════════════════════════════════

class _ChaineInfo {
  final String id, titre, resume;
  final Evenement derniereEtape;
  final int jourDernierVu, etapesCours;
  final bool terminee;
  final String? prochainId;

  const _ChaineInfo({
    required this.id,
    required this.titre,
    required this.derniereEtape,
    required this.resume,
    required this.jourDernierVu,
    required this.terminee,
    required this.prochainId,
    required this.etapesCours,
  });
}

class _EntreeHistorique {
  final Evenement evenement;
  final int jour;
  const _EntreeHistorique({
    required this.evenement,
    required this.jour,
  });
}
