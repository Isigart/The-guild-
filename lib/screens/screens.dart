// lib/screens/intro/titre_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'intro_screen.dart';

class TitreScreen extends StatelessWidget {
  const TitreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emblème animé
            const Text('⚔️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            
            // Titre principal
            Text(
              'Compagnie de\nMercenaires',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'LA GLOIRE OU L\'OUBLI',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 48),
            
            // Bouton commencer
            _BoutonTitre(
              label: 'Entrer dans la légende',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const IntroScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoutonTitre extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _BoutonTitre({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFC9A84C)),
          borderRadius: BorderRadius.circular(4),
          color: const Color(0xFF1A1000),
        ),
        child: Text(label, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// lib/screens/intro/intro_screen.dart
// ─────────────────────────────────────────────────────────

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  static const _paragraphes = [
    'Votre guilde est en ruines. Vos mercenaires sont partis chez la concurrence, emportant armes et réputation avec eux.',
    'Il vous reste ces murs éventrés et une décision désespérée — vendre les dernières reliques de votre ancienne gloire pour recruter ce que le marché propose de moins cher.',
    'Cinq manants. Pas de formation, pas de talent particulier, pas d\'ambition visible. Juste cinq personnes qui avaient besoin d\'argent et vous aussi.',
    'Une seule ambition vous reste : hisser votre guilde au sommet du royaume. Redevenir ce que vous étiez. Ou peut-être quelque chose de plus grand encore.',
    'C\'est avec ça que vous allez reconstruire.',
  ];

  int _paragrapheActuel = 0;
  bool _montrerInput = false;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _afficherProchain();
  }

  void _afficherProchain() {
    if (_paragrapheActuel >= _paragraphes.length) {
      setState(() => _montrerInput = true);
      return;
    }
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _paragrapheActuel++);
        _afficherProchain();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              // Titre parchemin
              Text('Chronique de la Compagnie',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 24),
              
              // Texte narratif
              Expanded(
                child: ListView.builder(
                  itemCount: _paragrapheActuel,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _paragraphes[i],
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.8,
                        color: Color(0xFFD4C49A),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Input nom de guilde
              if (_montrerInput) ...[
                const SizedBox(height: 24),
                Text('Donnez un nom à votre compagnie',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Color(0xFFF2E8C9)),
                  decoration: const InputDecoration(
                    hintText: 'Les Damnés du Roi...',
                    hintStyle: TextStyle(color: Color(0xFF6B5A3A)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF2A2015)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFC9A84C)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _BoutonTitre(
                  label: 'Que commence la légende →',
                  onTap: () {
                    // TODO: démarrer partie
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// lib/screens/guild/guilde_screen.dart
// ─────────────────────────────────────────────────────────

class GuildeScreen extends ConsumerWidget {
  const GuildeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          // Plan de la guilde (vue de dessus)
          const PlanGuildeWidget(),
          
          // Topbar
          const Positioned(
            top: 0, left: 0, right: 0,
            child: GuildeTopBar(),
          ),
          
          // Bouton équipe (tiroir gauche)
          // Bouton bâtiments (tiroir droit)
        ],
      ),
    );
  }
}

class PlanGuildeWidget extends ConsumerWidget {
  const PlanGuildeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Vue de dessus de la guilde
    // Grille de bâtiments + zones mystérieuses + porte de sortie
    return const Center(
      child: Text('Plan de la Guilde — TODO'),
    );
  }
}

class GuildeTopBar extends ConsumerWidget {
  const GuildeTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final or = ref.watch(orProvider);
    final jour = ref.watch(jourProvider);
    final renommee = ref.watch(renommeeProvider);
    
    return Container(
      color: const Color(0xFF0E0C08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bouton équipe
          _TopBarButton(label: '⚔️ Équipe', onTap: () {}),
          
          // Infos centrales
          Column(
            children: [
              Text('JOUR $jour', style: Theme.of(context).textTheme.titleSmall),
              Text(renommee.label, style: const TextStyle(fontSize: 10, color: Color(0xFF6B5A3A))),
            ],
          ),
          
          // Or + bâtiments
          Row(
            children: [
              Text('💰 $or', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
              _TopBarButton(label: '🔨', onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TopBarButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF2A2015)),
          borderRadius: BorderRadius.circular(4),
          color: const Color(0xFF0E0C08),
        ),
        child: Text(label, style: Theme.of(context).textTheme.titleSmall),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// lib/screens/mercenary/fiche_mercenaire_screen.dart
// ─────────────────────────────────────────────────────────

class FicheMercenaireScreen extends ConsumerWidget {
  final String mercId;
  const FicheMercenaireScreen({super.key, required this.mercId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mercs = ref.watch(mercenairesProvider);
    final merc = mercs.firstWhere((m) => m.id == mercId);

    return Scaffold(
      appBar: AppBar(
        title: Text(merc.nom, style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: const Color(0xFF0E0C08),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header classe + niveau
            _MercHeaderWidget(merc: merc),
            const SizedBox(height: 16),
            
            // Compteur points à distribuer
            _PointsDisponiblesWidget(merc: merc),
            const SizedBox(height: 16),
            
            // Grille des 8 stats
            _StatsGridWidget(merc: merc),
            const SizedBox(height: 16),
            
            // Substats
            _SubstatsWidget(merc: merc),
            const SizedBox(height: 16),
            
            // Sorts actifs
            _SortsWidget(merc: merc),
            const SizedBox(height: 16),
            
            // Historique des classes
            _HistoriqueWidget(merc: merc),
          ],
        ),
      ),
    );
  }
}

class _MercHeaderWidget extends StatelessWidget {
  final dynamic merc;
  const _MercHeaderWidget({required this.merc});

  @override
  Widget build(BuildContext context) {
    final pct = merc.hp / merc.hpMax;
    return Column(
      children: [
        Text(merc.classeActuelle.emoji, style: const TextStyle(fontSize: 48)),
        Text(merc.nom, style: Theme.of(context).textTheme.titleLarge),
        Text('${merc.classeActuelle.nom} • Niv. ${merc.niveau}',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: pct.clamp(0.0, 1.0),
          backgroundColor: const Color(0xFF2A1515),
          color: pct > 0.5
              ? const Color(0xFF2D6A2D)
              : pct > 0.25
                  ? const Color(0xFF7D6000)
                  : const Color(0xFF8B1A1A),
        ),
        Text('${merc.hp} / ${merc.hpMax} HP',
            style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}

class _PointsDisponiblesWidget extends ConsumerWidget {
  final dynamic merc;
  const _PointsDisponiblesWidget({required this.merc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pts = merc.pointsStatDisponibles;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: pts > 0 ? const Color(0xFFC9A84C) : const Color(0xFF2A2015),
        ),
        borderRadius: BorderRadius.circular(4),
        color: pts > 0
            ? const Color(0xFF1A1400)
            : const Color(0xFF0E0C08),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Points à distribuer',
              style: Theme.of(context).textTheme.titleSmall),
          Text(
            '$pts',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: pts > 0
                  ? const Color(0xFFF0D080)
                  : const Color(0xFF6B5A3A),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGridWidget extends ConsumerWidget {
  final dynamic merc;
  const _StatsGridWidget({required this.merc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = StatPrincipale.values;
    final pts = merc.pointsStatDisponibles;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) {
        final stat = stats[i];
        final valeur = merc.stats[stat] ?? 1;
        final peutDepenser = pts > 0;

        return GestureDetector(
          onTap: peutDepenser
              ? () => ref.read(gameProvider.notifier).distribuerStat(merc.id, stat)
              : null,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: peutDepenser
                    ? const Color(0xFF3A2A15)
                    : const Color(0xFF1A1A10),
              ),
              borderRadius: BorderRadius.circular(4),
              color: const Color(0xFF0E0C08),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat.shortLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B5A3A),
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '$valeur',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: valeur > 1
                        ? const Color(0xFFF0D080)
                        : const Color(0xFF2A2015),
                  ),
                ),
                if (peutDepenser)
                  const Text('+', style: TextStyle(color: Color(0xFFC9A84C), fontSize: 14)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SubstatsWidget extends StatelessWidget {
  final dynamic merc;
  const _SubstatsWidget({required this.merc});

  @override
  Widget build(BuildContext context) {
    final substats = merc.substats.entries
        .where((e) => e.value > 0)
        .toList();

    if (substats.isEmpty) {
      return Text('Aucune substat — assignez ce mercenaire à un poste.',
          style: Theme.of(context).textTheme.titleSmall);
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: substats.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1218),
            border: Border.all(color: const Color(0xFF1A2A35)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${e.key.label} ${e.value}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF5D9ABF)),
          ),
        );
      }).toList(),
    );
  }
}

class _SortsWidget extends StatelessWidget {
  final dynamic merc;
  const _SortsWidget({required this.merc});

  @override
  Widget build(BuildContext context) {
    if (merc.sortsActifs.isEmpty) {
      return Text('Aucun sort — évoluez en classe pour acquérir des sorts.',
          style: Theme.of(context).textTheme.titleSmall);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sorts actifs (${merc.sortsActifs.length}/4)',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...merc.sortsActifs.map((sort) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1400),
            border: Border.all(color: const Color(0xFF2A2010)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Text(sort.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sort.nom, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: const Color(0xFFC9A84C))),
                    Text(sort.description, style: const TextStyle(fontSize: 11, color: Color(0xFF6B5A3A))),
                  ],
                ),
              ),
              Text(
                sort.type == SortType.passif ? 'Passif' : 'CD ${sort.cooldown}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF8888FF)),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }
}

class _HistoriqueWidget extends StatelessWidget {
  final dynamic merc;
  const _HistoriqueWidget({required this.merc});

  @override
  Widget build(BuildContext context) {
    if (merc.historiqueClasses.isEmpty) return const SizedBox.shrink();

    return Text(
      'Parcours : ${merc.historiqueClasses.map((c) => '${c.emoji} ${c.nom}').join(' → ')} → ${merc.classeActuelle.emoji} ${merc.classeActuelle.nom}',
      style: const TextStyle(fontSize: 11, color: Color(0xFF6B5A3A), fontStyle: FontStyle.italic),
    );
  }
}

// ─────────────────────────────────────────────────────────
// lib/screens/combat/selection_equipe_screen.dart
// ─────────────────────────────────────────────────────────

class SelectionEquipeScreen extends ConsumerWidget {
  final dynamic zone;
  const SelectionEquipeScreen({super.key, required this.zone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mercs = ref.watch(mercenairesProvider);
    final equipe = ref.watch(gameProvider)?.equipeDeCombaIds ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Choisir l\'équipe — ${equipe.length}/5'),
        backgroundColor: const Color(0xFF0E0C08),
      ),
      body: Column(
        children: [
          // Infos zone
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF16130C),
            child: Text(
              zone.nomAffiche,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          
          // Liste des mercenaires
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: mercs.length,
              itemBuilder: (_, i) {
                final merc = mercs[i];
                final selectionne = equipe.contains(merc.id);
                final disponible = merc.peutCombattre;

                return GestureDetector(
                  onTap: disponible
                      ? () => ref.read(gameProvider.notifier).toggleCombattant(merc.id)
                      : null,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectionne
                            ? const Color(0xFFC9A84C)
                            : disponible
                                ? const Color(0xFF2A2015)
                                : const Color(0xFF1A1010),
                      ),
                      borderRadius: BorderRadius.circular(4),
                      color: selectionne
                          ? const Color(0xFF1A1600)
                          : const Color(0xFF16130C),
                    ),
                    child: Row(
                      children: [
                        Text(merc.classeActuelle.emoji,
                            style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(merc.nom,
                                  style: Theme.of(context).textTheme.titleMedium),
                              Text('${merc.classeActuelle.nom} • Niv. ${merc.niveau}',
                                  style: Theme.of(context).textTheme.titleSmall),
                            ],
                          ),
                        ),
                        if (merc.estBlesse)
                          const Text('🩸 Blessé',
                              style: TextStyle(color: Color(0xFFC0392B), fontSize: 12))
                        else if (selectionne)
                          const Text('✓',
                              style: TextStyle(color: Color(0xFFC9A84C), fontSize: 20))
                        else if (!disponible)
                          const Text('—',
                              style: TextStyle(color: Color(0xFF6B5A3A), fontSize: 20)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Bouton confirmer
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: equipe.length == 5
                    ? () {
                        // TODO: lancer CombatScreen
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A0500),
                  side: const BorderSide(color: Color(0xFF8B1A1A)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  equipe.length == 5
                      ? '⚔️ Partir au Combat'
                      : 'Sélectionnez ${5 - equipe.length} mercenaire(s)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFC0392B),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

export 'main_screen.dart';
export 'guild/guild_screen.dart';
export 'zone/zone_screen.dart';
export 'combat/combat_screen.dart';
export 'combat/post_combat_screen.dart';
export 'evenement/evenement_popup.dart';
export 'coffre/coffre_screen.dart';
export 'journal/journal_screen.dart';
export 'mercenaires/mercenaires_screen.dart';

export 'loading_screen.dart';
