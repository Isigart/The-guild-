// lib/screens/mercenaires/mercenaires_screen.dart
// Écran mercenaires — liste, stats, classe, blessures, équipe combat

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/mercenaire.dart';
import '../../models/enums.dart';
import '../../models/classe.dart';
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
const _rouge  = Color(0xFFC0392B);
const _vert   = Color(0xFF27AE60);

Color _couleurStatut(MercenaireSatut s) {
  switch (s) {
    case MercenaireSatut.libre:    return _vert;
    case MercenaireSatut.poste:    return const Color(0xFF4169E1);
    case MercenaireSatut.combat:   return _or;
    case MercenaireSatut.blesse:   return const Color(0xFFE67E22);
    case MercenaireSatut.critique: return _rouge;
    case MercenaireSatut.reve:     return const Color(0xFF8B008B);
    default:                       return _dim;
  }
}

String _labelStatut(MercenaireSatut s) {
  switch (s) {
    case MercenaireSatut.libre:    return '✅ Disponible';
    case MercenaireSatut.poste:    return '🔧 Au poste';
    case MercenaireSatut.combat:   return '⚔️ En équipe';
    case MercenaireSatut.blesse:   return '🩸 Blessé';
    case MercenaireSatut.critique: return '💀 Critique';
    case MercenaireSatut.reve:     return '💤 En rêve';
    default:                       return '❓';
  }
}

// ══════════════════════════════════════════════════════
// ÉCRAN PRINCIPAL
// ══════════════════════════════════════════════════════

class MercenairesScreen extends ConsumerWidget {
  const MercenairesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(gameProvider);
    if (etat == null) return const SizedBox.shrink();

    final mercs       = etat.mercenaires;
    final equipe      = etat.equipeDeCombaIds;
    final disponibles = mercs.where((m) => m.estDisponible).length;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _Header(
            total:      mercs.length,
            disponibles: disponibles,
            equipe:     equipe.length,
          ),
          Expanded(
            child: mercs.isEmpty
                ? _MessageVide()
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: mercs.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) => _CarteMercenaire(
                      mercenaire: mercs[i],
                      dansEquipe: equipe.contains(mercs[i].id),
                      onTap: () => _ouvrirDetail(
                          context, mercs[i], ref),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _ouvrirDetail(
      BuildContext ctx, Mercenaire m, WidgetRef ref) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(ctx),
        child: _MercSheet(mercenaire: m),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// HEADER
// ══════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final int total, disponibles, equipe;
  const _Header({
    required this.total,
    required this.disponibles,
    required this.equipe,
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
        const Text('⚔️', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MERCENAIRES',
                  style: TextStyle(
                      color: _or, fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5)),
              Text(
                '$total mercenaires · '
                '$disponibles disponibles · '
                '$equipe en équipe',
                style: const TextStyle(
                    color: _dim, fontSize: 10,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════
// CARTE MERCENAIRE (liste)
// ══════════════════════════════════════════════════════

class _CarteMercenaire extends StatelessWidget {
  final Mercenaire mercenaire;
  final bool dansEquipe;
  final VoidCallback onTap;
  const _CarteMercenaire({
    required this.mercenaire,
    required this.dansEquipe,
    required this.onTap,
  });

  Mercenaire get m => mercenaire;

  @override
  Widget build(BuildContext context) {
    final couleurStat = _couleurStatut(m.statut);
    final hpRatio = m.hpMax > 0
        ? (m.hp / m.hpMax).clamp(0.0, 1.0) : 0.0;
    final xpRatio = (100 + m.niveau * 150) > 0
        ? (m.xp / (100 + m.niveau * 150)).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _bg3,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: dansEquipe
                ? _orDim.withOpacity(0.5)
                : (m.estBlesse
                    ? _rouge.withOpacity(0.3)
                    : _border),
            width: dansEquipe ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Sprite + compagnon
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: _bg2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _border),
                    ),
                    child: Center(
                      child: Text(
                        m.classeActuelle.emoji,
                        style: const TextStyle(
                            fontSize: 26),
                      ),
                    ),
                  ),
                  // Badge classe
                  Positioned(
                    bottom: -2, right: -4,
                    child: Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        color: _bg,
                        borderRadius:
                            BorderRadius.circular(4),
                        border: Border.all(
                            color: _border,
                            width: 0.5),
                      ),
                      child: Center(
                        child: Text(
                          m.classeActuelle.badge,
                          style: const TextStyle(
                              fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  // Compagnon
                  if (m.classeActuelle.compagnon != null)
                    Positioned(
                      top: -4, left: -4,
                      child: Container(
                        width: 16, height: 16,
                        decoration: BoxDecoration(
                          color: _bg,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: _border,
                              width: 0.5),
                        ),
                        child: Center(
                          child: Text(
                            m.classeActuelle
                                .compagnon!.emoji,
                            style: const TextStyle(
                                fontSize: 9),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Infos principales
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // Nom + statut
                    Row(
                      children: [
                        Expanded(
                          child: Text(m.nom,
                              style: const TextStyle(
                                  color: _texte,
                                  fontSize: 13,
                                  fontWeight:
                                      FontWeight.w700)),
                        ),
                        _BadgePetit(
                          label: _labelStatut(m.statut),
                          couleur: couleurStat,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Classe + niveau
                    Row(
                      children: [
                        Text(
                          m.classeActuelle.nom,
                          style: const TextStyle(
                              color: _dim,
                              fontSize: 10),
                        ),
                        const SizedBox(width: 6),
                        Text('Niv.${m.niveau}',
                            style: const TextStyle(
                                color: _orDim,
                                fontSize: 10,
                                fontWeight:
                                    FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // HP bar
                    _MiniBar(
                      ratio: hpRatio,
                      couleur: hpRatio > 0.5
                          ? _vert
                          : hpRatio > 0.25
                              ? _or
                              : _rouge,
                      label: '❤️',
                    ),
                    const SizedBox(height: 3),

                    // XP bar
                    _MiniBar(
                      ratio: xpRatio,
                      couleur: const Color(0xFF4169E1),
                      label: '✨',
                    ),

                    // Blessure
                    if (m.estBlesse) ...[
                      const SizedBox(height: 4),
                      Text(
                        '🩸 ${_labelGravite(m.gravite)} — '
                        '${m.joursRestantsInfirmerie}j restants',
                        style: TextStyle(
                            color: _rouge.withOpacity(0.8),
                            fontSize: 9,
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),

              // Indicateur équipe
              if (dansEquipe)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: _or.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: _orDim.withOpacity(0.4)),
                  ),
                  child: const Text('ÉQUIPE',
                      style: TextStyle(
                          color: _orDim,
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _labelGravite(GraviteBlessure? g) {
    switch (g) {
      case GraviteBlessure.legere:   return 'Légère';
      case GraviteBlessure.moyenne:  return 'Moyenne';
      case GraviteBlessure.grave:    return 'Grave';
      case GraviteBlessure.critique: return 'Critique';
      default:                       return 'Blessé';
    }
  }
}

class _MiniBar extends StatelessWidget {
  final double ratio;
  final Color couleur;
  final String label;
  const _MiniBar({
    required this.ratio, required this.couleur,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label, style: const TextStyle(fontSize: 8)),
      const SizedBox(width: 4),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: Colors.white.withOpacity(0.05),
            valueColor: AlwaysStoppedAnimation(couleur),
            minHeight: 4,
          ),
        ),
      ),
    ],
  );
}

class _BadgePetit extends StatelessWidget {
  final String label;
  final Color couleur;
  const _BadgePetit({required this.label, required this.couleur});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: couleur.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(
          color: couleur.withOpacity(0.3), width: 0.5),
    ),
    child: Text(label,
        style: TextStyle(
            color: couleur, fontSize: 8,
            fontWeight: FontWeight.w700)),
  );
}

// ══════════════════════════════════════════════════════
// DETAIL MERCENAIRE (bottom sheet)
// ══════════════════════════════════════════════════════

class _MercSheet extends ConsumerStatefulWidget {
  final Mercenaire mercenaire;
  const _MercSheet({required this.mercenaire});

  @override
  ConsumerState<_MercSheet> createState() => _MercSheetState();
}

class _MercSheetState extends ConsumerState<_MercSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Mercenaire get m => widget.mercenaire;

  @override
  Widget build(BuildContext context) {
    final etat   = ref.watch(gameProvider);
    if (etat == null) return const SizedBox.shrink();
    final equipe = etat.equipeDeCombaIds;
    final dansEquipe = equipe.contains(m.id);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0C0A06),
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(
            top:   BorderSide(color: _border),
            left:  BorderSide(color: _border),
            right: BorderSide(color: _border),
          ),
        ),
        child: Column(
          children: [
            // Poignée
            Center(
              child: Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 8),
                width: 36, height: 3,
                decoration: BoxDecoration(
                    color: _border,
                    borderRadius:
                        BorderRadius.circular(2)),
              ),
            ),

            // En-tête mercenaire
            _SheetHeader(
              mercenaire: m,
              dansEquipe: dansEquipe,
              onToggleEquipe: () => _toggleEquipe(ref),
            ),

            // Tabs
            TabBar(
              controller: _tabs,
              labelColor: _or,
              unselectedLabelColor: _dim,
              indicatorColor: _or,
              indicatorWeight: 1.5,
              labelStyle: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1),
              tabs: const [
                Tab(text: 'STATS'),
                Tab(text: 'CLASSE'),
                Tab(text: 'SUBSTATS'),
              ],
            ),

            // Contenu tabs
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _TabStats(mercenaire: m),
                  _TabClasse(mercenaire: m),
                  _TabSubstats(mercenaire: m),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleEquipe(WidgetRef ref) {
    final etat  = ref.read(gameProvider);
    final notif = ref.read(gameProvider.notifier);
    if (etat == null) return;

    final equipe = etat.equipeDeCombaIds;
    if (equipe.contains(m.id)) {
      notif.retirerDeEquipe(m.id);
    } else {
      if (!m.peutCombattre) return;
      notif.ajouterAEquipe(m.id);
    }
    setState(() {});
  }
}

// ── En-tête du sheet ──
class _SheetHeader extends StatelessWidget {
  final Mercenaire mercenaire;
  final bool dansEquipe;
  final VoidCallback onToggleEquipe;
  const _SheetHeader({
    required this.mercenaire, required this.dansEquipe,
    required this.onToggleEquipe,
  });

  Mercenaire get m => mercenaire;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
    child: Row(
      children: [
        // Sprite
        Stack(
          clipBehavior: Clip.none,
          children: [
            Text(m.classeActuelle.emoji,
                style: const TextStyle(fontSize: 40)),
            if (m.classeActuelle.compagnon != null)
              Positioned(
                bottom: -4, left: -4,
                child: Text(
                  m.classeActuelle.compagnon!.emoji,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),

        // Infos
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.nom,
                  style: const TextStyle(
                      color: _texte, fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                '${m.classeActuelle.nom}  ·  Niv.${m.niveau}  ·  '
                '${m.xp}/${100 + m.niveau * 150} XP',
                style: const TextStyle(
                    color: _dim, fontSize: 10),
              ),
              if (m.estBlesse) ...[
                const SizedBox(height: 4),
                Text(
                  '🩸 Blessure ${_grav(m.gravite)} — '
                  '${m.joursRestantsInfirmerie} jours',
                  style: TextStyle(
                      color: _rouge.withOpacity(0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),

        // Bouton équipe
        GestureDetector(
          onTap: (!dansEquipe && !m.peutCombattre)
              ? null
              : onToggleEquipe,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: dansEquipe
                  ? _or.withOpacity(0.12)
                  : (m.peutCombattre
                      ? _vert.withOpacity(0.08)
                      : _bg3),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: dansEquipe
                    ? _orDim.withOpacity(0.5)
                    : (m.peutCombattre
                        ? _vert.withOpacity(0.3)
                        : _border),
              ),
            ),
            child: Text(
              dansEquipe ? '− Équipe' : '+ Équipe',
              style: TextStyle(
                  color: dansEquipe
                      ? _or
                      : (m.peutCombattre
                          ? _vert : _dim),
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    ),
  );

  String _grav(GraviteBlessure? g) {
    switch (g) {
      case GraviteBlessure.legere:   return 'légère';
      case GraviteBlessure.moyenne:  return 'moyenne';
      case GraviteBlessure.grave:    return 'grave';
      case GraviteBlessure.critique: return 'critique';
      default:                       return '';
    }
  }
}

// ══════════════════════════════════════════════════════
// TAB STATS
// ══════════════════════════════════════════════════════

class _TabStats extends StatelessWidget {
  final Mercenaire mercenaire;
  const _TabStats({required this.mercenaire});

  @override
  Widget build(BuildContext context) {
    final m = mercenaire;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats principales
        _SectionLabel('STATS PRINCIPALES'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: StatPrincipale.values.map((s) =>
            _ChipStat(
              label: s.name.toUpperCase(),
              valeur: m.stats[s] ?? 1,
            ),
          ).toList(),
        ),

        const SizedBox(height: 16),

        // Stats combat calculées
        _SectionLabel('COMBAT'),
        const SizedBox(height: 8),
        _GrilleStat(stats: [
          ('⚔️ ATK',   m.atk.toString()),
          ('🔮 ATK Mag', m.atkMagique.toString()),
          ('🛡️ Armure', m.armure.toString()),
          ('⚡ Init',   m.initiative.toString()),
          ('🎯 Crit',  '${(m.chanceCritique * 100).toStringAsFixed(0)}%'),
          ('❤️ HP Max', m.hpMax.toString()),
        ]),

        // Points de stat disponibles
        if (m.pointsStatDisponibles > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _or.withOpacity(0.06),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: _orDim.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Text('💫',
                    style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  '${m.pointsStatDisponibles} point'
                  '${m.pointsStatDisponibles > 1 ? 's' : ''} '
                  'de stat disponibles',
                  style: const TextStyle(
                      color: _or,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],

        // Compagnon
        if (m.classeActuelle.compagnon != null) ...[
          const SizedBox(height: 16),
          _SectionLabel('COMPAGNON'),
          const SizedBox(height: 8),
          _BlockCompagnon(
            compagnon: m.classeActuelle.compagnon!,
            merc: m,
          ),
        ],
      ],
    );
  }
}

class _ChipStat extends StatelessWidget {
  final String label;
  final int valeur;
  const _ChipStat({required this.label, required this.valeur});

  Color get _couleur {
    if (valeur >= 15) return const Color(0xFF27AE60);
    if (valeur >= 10) return _or;
    if (valeur >= 6)  return _texte;
    return _dim;
  }

  @override
  Widget build(BuildContext context) => Container(
    width: 72,
    padding: const EdgeInsets.symmetric(
        vertical: 8, horizontal: 4),
    decoration: BoxDecoration(
      color: _bg3,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: _border),
    ),
    child: Column(
      children: [
        Text('$valeur',
            style: TextStyle(
                color: _couleur, fontSize: 18,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(
                color: _dim, fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      ],
    ),
  );
}

class _GrilleStat extends StatelessWidget {
  final List<(String, String)> stats;
  const _GrilleStat({required this.stats});

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 2.2,
    ),
    itemCount: stats.length,
    itemBuilder: (_, i) => Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _bg3,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(stats[i].$1,
              style: const TextStyle(
                  color: _dim, fontSize: 10)),
          Text(stats[i].$2,
              style: const TextStyle(
                  color: _texte, fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    ),
  );
}

class _BlockCompagnon extends StatelessWidget {
  final CompagnonData compagnon;
  final Mercenaire merc;
  const _BlockCompagnon({
    required this.compagnon, required this.merc,
  });

  @override
  Widget build(BuildContext context) {
    final hpComp = (merc.hpMax * compagnon.hpMulti).round();
    final atkComp = (merc.atk  * compagnon.atkMulti).round();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bg3,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Text(compagnon.emoji,
              style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(compagnon.nom,
                    style: const TextStyle(
                        color: _texte, fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _MiniStatComp('❤️', '$hpComp HP'),
                    const SizedBox(width: 8),
                    _MiniStatComp('⚔️', '$atkComp ATK'),
                    const SizedBox(width: 8),
                    _MiniStatComp(
                        '⚡', '${compagnon.initiative} Init'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatComp extends StatelessWidget {
  final String emoji, valeur;
  const _MiniStatComp(this.emoji, this.valeur);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(emoji, style: const TextStyle(fontSize: 9)),
      const SizedBox(width: 2),
      Text(valeur,
          style: const TextStyle(
              color: _dim, fontSize: 9)),
    ],
  );
}

// ══════════════════════════════════════════════════════
// TAB CLASSE
// ══════════════════════════════════════════════════════

class _TabClasse extends StatelessWidget {
  final Mercenaire mercenaire;
  const _TabClasse({required this.mercenaire});

  @override
  Widget build(BuildContext context) {
    final m = mercenaire;
    final c = m.classeActuelle;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Classe actuelle
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _bg3,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: _orDim.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Text(c.emoji,
                  style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(c.nom,
                              style: const TextStyle(
                                  color: _or,
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight.w800)),
                        ),
                        _TierBadge(c.tier),
                      ],
                    ),
                    if (c.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(c.description,
                          style: const TextStyle(
                              color: _dim,
                              fontSize: 10,
                              height: 1.4,
                              fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Sorts actifs
        if (m.sortsActifs.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionLabel('SORTS'),
          const SizedBox(height: 8),
          ...m.sortsActifs.map((s) => _LigneSort(sort: s)),
        ],

        // Historique classes
        if (m.historiqueClasses.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionLabel('HISTORIQUE'),
          const SizedBox(height: 8),
          ...m.historiqueClasses.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text(c.emoji,
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(c.nom,
                    style: const TextStyle(
                        color: _dim, fontSize: 11)),
                const Spacer(),
                _TierBadge(c.tier),
              ],
            ),
          )),
        ],
      ],
    );
  }
}

class _TierBadge extends StatelessWidget {
  final ClasseTier tier;
  const _TierBadge(this.tier);

  String get label {
    switch (tier) {
      case ClasseTier.base: return 'BASE';
      case ClasseTier.t1:   return 'T1';
      case ClasseTier.t2:   return 'T2';
      case ClasseTier.t3:   return 'T3';
      case ClasseTier.t4:   return 'T4';
    }
  }

  Color get couleur {
    switch (tier) {
      case ClasseTier.base: return _dim;
      case ClasseTier.t1:   return const Color(0xFF27AE60);
      case ClasseTier.t2:   return const Color(0xFF4169E1);
      case ClasseTier.t3:   return const Color(0xFF8B008B);
      case ClasseTier.t4:   return _or;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: couleur.withOpacity(0.12),
      borderRadius: BorderRadius.circular(3),
      border: Border.all(
          color: couleur.withOpacity(0.35), width: 0.5),
    ),
    child: Text(label,
        style: TextStyle(
            color: couleur, fontSize: 9,
            fontWeight: FontWeight.w800)),
  );
}

class _LigneSort extends StatelessWidget {
  final dynamic sort;
  const _LigneSort({required this.sort});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: _bg3,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: _border),
    ),
    child: Row(
      children: [
        Text(sort.emoji ?? '✨',
            style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sort.nom ?? sort.id,
                  style: const TextStyle(
                      color: _texte, fontSize: 11,
                      fontWeight: FontWeight.w600)),
              if (sort.description != null)
                Text(sort.description,
                    style: const TextStyle(
                        color: _dim, fontSize: 9)),
            ],
          ),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════
// TAB SUBSTATS
// ══════════════════════════════════════════════════════

class _TabSubstats extends StatelessWidget {
  final Mercenaire mercenaire;
  const _TabSubstats({required this.mercenaire});

  @override
  Widget build(BuildContext context) {
    final m = mercenaire;
    final substatsNonNuls = Substat.values
        .where((s) => (m.substats[s] ?? 0) > 0)
        .toList()
      ..sort((a, b) =>
          (m.substats[b] ?? 0).compareTo(m.substats[a] ?? 0));

    if (substatsNonNuls.isEmpty) {
      return const Center(
        child: Text(
          'Aucune substat développée.\n'
          'Assignez ce mercenaire à un bâtiment.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: _dim, fontSize: 11,
              fontStyle: FontStyle.italic),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionLabel('COMPÉTENCES CIVILES'),
        const SizedBox(height: 10),
        ...substatsNonNuls.map((s) => _LigneSubstat(
          substat: s,
          valeur:  m.substats[s] ?? 0,
        )),
      ],
    );
  }
}

class _LigneSubstat extends StatelessWidget {
  final Substat substat;
  final int valeur;
  const _LigneSubstat({
    required this.substat, required this.valeur,
  });

  Color get _couleur {
    if (valeur >= 40) return _or;
    if (valeur >= 25) return const Color(0xFF8B008B);
    if (valeur >= 15) return const Color(0xFF4169E1);
    if (valeur >= 8)  return const Color(0xFF27AE60);
    return _dim;
  }

  String get _niveau {
    if (valeur >= 40) return 'Maître';
    if (valeur >= 25) return 'Expert';
    if (valeur >= 15) return 'Intermédiaire';
    if (valeur >= 8)  return 'Débutant';
    return 'Novice';
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(
        horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: _bg3,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
          color: _couleur.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(substat.nom,
                  style: TextStyle(
                      color: _couleur, fontSize: 11,
                      fontWeight: FontWeight.w600)),
              Text(_niveau,
                  style: TextStyle(
                      color: _couleur.withOpacity(0.5),
                      fontSize: 9)),
            ],
          ),
        ),
        Text('$valeur',
            style: TextStyle(
                color: _couleur, fontSize: 16,
                fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════
// HELPERS
// ══════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label,
          style: const TextStyle(
              color: _orDim, fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 2)),
      Expanded(
        child: Container(
          height: 1,
          margin: const EdgeInsets.only(left: 8),
          color: _border,
        ),
      ),
    ],
  );
}

class _MessageVide extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('⚔️', style: TextStyle(fontSize: 36)),
        SizedBox(height: 12),
        Text('Aucun mercenaire.',
            style: TextStyle(
                color: _dim, fontSize: 13,
                fontStyle: FontStyle.italic)),
        SizedBox(height: 4),
        Text('Recrutez depuis le bureau.',
            style: TextStyle(
                color: _dim, fontSize: 10)),
      ],
    ),
  );
}
