// lib/screens/combat/combat_screen.dart
// Écran de combat complet
// Deux demi-écrans face à face — ennemis haut, héros bas
// Perspective par position : AVANT grand, ARRIÈRE petit

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/combat_models.dart';
import '../../models/enums.dart';
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
const _rouge  = Color(0xFF8B1A1A);
const _vert   = Color(0xFF145214);

// Taille sprite selon position
double _tailleSprite(Position pos, {bool estEnnemi = false}) {
  switch (pos) {
    case Position.avant:   return estEnnemi ? 42.0 : 38.0;
    case Position.milieu:  return estEnnemi ? 32.0 : 30.0;
    case Position.arriere: return estEnnemi ? 24.0 : 22.0;
  }
}

double _opacitePosition(Position pos) {
  switch (pos) {
    case Position.avant:   return 1.0;
    case Position.milieu:  return 0.88;
    case Position.arriere: return 0.72;
  }
}

// Vitesse de tick selon multiplicateur
const _tickDurees = {
  1: Duration(milliseconds: 800),
  2: Duration(milliseconds: 400),
  3: Duration(milliseconds: 200),
  0: Duration(milliseconds: 0), // AUTO
};

// ══════════════════════════════════════════════════════
// ÉTAT LOCAL DU COMBAT
// ══════════════════════════════════════════════════════

class _CombatLocalState {
  EtatCombat etat;
  bool pause;
  int vitesse;         // 1, 2, 3, 0=auto
  bool fuiteInterdite;
  List<String> log;    // dernières actions

  _CombatLocalState({
    required this.etat,
    this.pause = false,
    this.vitesse = 2,
    this.fuiteInterdite = false,
    List<String>? log,
  }) : log = log ?? [];
}

// ══════════════════════════════════════════════════════
// ÉCRAN PRINCIPAL
// ══════════════════════════════════════════════════════

class CombatScreen extends ConsumerStatefulWidget {
  final EtatCombat etatInitial;
  final String souZoneId;
  final bool fuiteInterdite;
  final void Function(EtatCombat) onFin;

  const CombatScreen({
    super.key,
    required this.etatInitial,
    required this.souZoneId,
    this.fuiteInterdite = false,
    required this.onFin,
  });

  @override
  ConsumerState<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends ConsumerState<CombatScreen>
    with TickerProviderStateMixin {
  late _CombatLocalState _local;
  Timer? _timer;

  // Animations
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _local = _CombatLocalState(
      etat: widget.etatInitial,
      fuiteInterdite: widget.fuiteInterdite,
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _demarrerTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Timer des ticks ──
  void _demarrerTimer() {
    _timer?.cancel();
    if (_local.pause || _local.etat.termine) return;

    if (_local.vitesse == 0) {
      // AUTO — exécuter jusqu'à la fin
      _executerJusquALaFin();
      return;
    }

    final duree = _tickDurees[_local.vitesse] ??
        const Duration(milliseconds: 400);
    _timer = Timer.periodic(duree, (_) {
      if (!mounted) return;
      _executerTick();
    });
  }

  void _executerTick() {
    if (_local.etat.termine) {
      _timer?.cancel();
      _finCombat();
      return;
    }
    setState(() {
      _local.etat = ref.read(gameProvider.notifier)
          .executerTickCombat(_local.etat);

      // Log actions
      for (final action in _local.etat.actionsTickActuel) {
        _local.log.add(action.texte);
        if (_local.log.length > 20) _local.log.removeAt(0);
      }
    });

    if (_local.etat.termine) {
      _timer?.cancel();
      Future.delayed(const Duration(milliseconds: 800), _finCombat);
    }
  }

  void _executerJusquALaFin() {
    setState(() {
      while (!_local.etat.termine) {
        _local.etat = ref.read(gameProvider.notifier)
            .executerTickCombat(_local.etat);
      }
    });
    Future.delayed(const Duration(milliseconds: 500), _finCombat);
  }

  void _finCombat() {
    if (!mounted) return;
    widget.onFin(_local.etat);
  }

  void _togglePause() {
    setState(() => _local.pause = !_local.pause);
    if (_local.pause) {
      _timer?.cancel();
    } else {
      _demarrerTimer();
    }
  }

  void _changerVitesse(int v) {
    setState(() => _local.vitesse = v);
    _demarrerTimer();
  }

  void _fuir() {
    if (_local.fuiteInterdite) return;
    _timer?.cancel();
    setState(() {
      _local.etat = ref.read(gameProvider.notifier)
          .fuirCombat(_local.etat);
    });
    Future.delayed(const Duration(milliseconds: 400), _finCombat);
  }

  void _passerTour() {
    if (_local.pause) _executerTick();
  }

  // ══════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final etat = _local.etat;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // Header
          _CombatHeader(
            souZoneId: widget.souZoneId,
            tick: etat.tick,
            fuiteInterdite: _local.fuiteInterdite,
            pause: _local.pause,
            onPause: _togglePause,
          ),

          // Champ de bataille
          Expanded(
            child: Stack(
              children: [
                // Fond atmosphérique
                _FondAtmospherique(zoneId: widget.souZoneId),

                Column(
                  children: [
                    // ── Demi-écran ennemis ──
                    Expanded(
                      child: _DemiEcranEnnemis(
                        ennemis: etat.ennemis,
                        pulse: _pulse,
                      ),
                    ),

                    // Frontière
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.transparent,
                          _or.withOpacity(0.12),
                          _or.withOpacity(0.18),
                          _or.withOpacity(0.12),
                          Colors.transparent,
                        ]),
                      ),
                    ),

                    // ── Demi-écran héros ──
                    Expanded(
                      child: _DemiEcranHeros(
                        heroes: etat.heroes,
                        pulse: _pulse,
                      ),
                    ),
                  ],
                ),

                // Overlay fin de combat
                if (etat.termine)
                  _OverlayFin(
                    victoire: etat.victoire,
                    fuite: etat.fuite,
                  ),
              ],
            ),
          ),

          // Panel de contrôle
          _PanelControle(
            pause: _local.pause,
            vitesse: _local.vitesse,
            fuiteInterdite: _local.fuiteInterdite,
            onPause: _togglePause,
            onPasser: _passerTour,
            onFuir: _fuir,
            onVitesse: _changerVitesse,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// HEADER COMBAT
// ══════════════════════════════════════════════════════

class _CombatHeader extends StatelessWidget {
  final String souZoneId;
  final int tick;
  final bool fuiteInterdite, pause;
  final VoidCallback onPause;

  const _CombatHeader({
    required this.souZoneId, required this.tick,
    required this.fuiteInterdite, required this.pause,
    required this.onPause,
  });

  String get _nomZone {
    final parts = souZoneId.split('-');
    final z = parts[0];
    final e = parts[1];
    const noms = {'1': 'Chemin', '2': 'Forêt', '3': 'Marais',
                  '4': 'Mines', '5': 'Citadelle'};
    final boss = e == 'B';
    return '${noms[z] ?? 'Zone $z'} ${boss ? "— Boss" : "— $souZoneId"}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          14, MediaQuery.of(context).padding.top + 6, 14, 8),
      decoration: const BoxDecoration(
        color: Color(0xFF060402),
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_nomZone,
                    style: const TextStyle(
                        color: _or, fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2)),
                if (fuiteInterdite)
                  const Text('Fuite impossible',
                      style: TextStyle(
                          color: Color(0xFFE74C3C),
                          fontSize: 9,
                          fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _bg3,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                Text('$tick',
                    style: const TextStyle(
                        color: _or, fontSize: 14,
                        fontWeight: FontWeight.w800)),
                const Text('ROUND',
                    style: TextStyle(
                        color: _dim, fontSize: 7,
                        letterSpacing: 1.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onPause,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: pause ? _or.withOpacity(0.1) : _bg3,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: pause ? _orDim : _border),
              ),
              child: Center(
                child: Text(pause ? '▶' : '⏸',
                    style: TextStyle(
                        fontSize: 14,
                        color: pause ? _or : _dim)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// FOND ATMOSPHÉRIQUE
// ══════════════════════════════════════════════════════

class _FondAtmospherique extends StatelessWidget {
  final String zoneId;
  const _FondAtmospherique({required this.zoneId});

  Color get _couleurHaut {
    final z = int.tryParse(zoneId.split('-')[0]) ?? 1;
    switch (z) {
      case 1: return const Color(0xFF1A3A1A);
      case 2: return const Color(0xFF0A1A0A);
      case 3: return const Color(0xFF1A1A0A);
      case 4: return const Color(0xFF2A1A0A);
      case 5: return const Color(0xFF1A0A0A);
      default: return const Color(0xFF1A1A1A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _couleurHaut.withOpacity(0.3),
              _bg,
              _bg,
              const Color(0xFF0A1A0A).withOpacity(0.2),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// DEMI-ÉCRAN ENNEMIS (haut)
// AVANT = bas de leur zone = grand
// ══════════════════════════════════════════════════════

class _DemiEcranEnnemis extends StatelessWidget {
  final List<EnnemiCombat> ennemis;
  final Animation<double> pulse;
  const _DemiEcranEnnemis({required this.ennemis, required this.pulse});

  @override
  Widget build(BuildContext context) {
    // Grouper par position
    final arriere = ennemis.where(
        (e) => e.position == Position.arriere).toList();
    final milieu  = ennemis.where(
        (e) => e.position == Position.milieu).toList();
    final avant   = ennemis.where(
        (e) => e.position == Position.avant).toList();

    // Alerte boss
    final bossAlerte = ennemis
        .where((e) => e.capaSpecialeEnPreparation != null && e.estVivant)
        .firstOrNull;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // ARRIÈRE — haut, petits
        if (arriere.isNotEmpty)
          _RangeeEnnemis(
              ennemis: arriere, position: Position.arriere, pulse: pulse),

        // MILIEU
        if (milieu.isNotEmpty)
          _RangeeEnnemis(
              ennemis: milieu, position: Position.milieu, pulse: pulse),

        // AVANT — bas, grands
        _RangeeEnnemis(
            ennemis: avant, position: Position.avant, pulse: pulse),

        // Alerte
        if (bossAlerte != null)
          AnimatedBuilder(
            animation: pulse,
            builder: (_, __) => Opacity(
              opacity: pulse.value * 0.6,
              child: Text(
                '⚡ ${bossAlerte.capaSpecialeEnPreparation}...',
                style: const TextStyle(
                    color: Color(0xFFFF7070),
                    fontSize: 9,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.5),
              ),
            ),
          ),
      ],
    );
  }
}

class _RangeeEnnemis extends StatelessWidget {
  final List<EnnemiCombat> ennemis;
  final Position position;
  final Animation<double> pulse;
  const _RangeeEnnemis({
    required this.ennemis, required this.position,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: ennemis.map((e) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: _SpriteEnnemi(ennemi: e, position: position, pulse: pulse),
    )).toList(),
  );
}

// ── Sprite ennemi ──
class _SpriteEnnemi extends StatefulWidget {
  final EnnemiCombat ennemi;
  final Position position;
  final Animation<double> pulse;
  const _SpriteEnnemi({
    required this.ennemi, required this.position,
    required this.pulse,
  });

  @override
  State<_SpriteEnnemi> createState() => _SpriteEnnemiState();
}

class _SpriteEnnemiState extends State<_SpriteEnnemi>
    with SingleTickerProviderStateMixin {
  late AnimationController _bob;
  late Animation<double> _bobAnim;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2500 +
          widget.ennemi.id.hashCode.abs() % 1000),
    )..repeat(reverse: true);
    _bobAnim = Tween<double>(begin: 0, end: -5).animate(
        CurvedAnimation(parent: _bob, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e    = widget.ennemi;
    final taille = _tailleSprite(widget.position, estEnnemi: true);
    final opacite = e.estVaincu ? 0.12 :
        _opacitePosition(widget.position);

    return Opacity(
      opacity: opacite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sprite
          AnimatedBuilder(
            animation: _bobAnim,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, e.estVaincu ? 0 : _bobAnim.value),
              child: child,
            ),
            child: Text(e.emoji,
                style: TextStyle(
                    fontSize: taille,
                    shadows: [
                      Shadow(
                        color: _rouge.withOpacity(0.5),
                        blurRadius: 12,
                      ),
                    ])),
          ),

          const SizedBox(height: 3),

          // HP bar
          _HpBar(
            courant: e.hp,
            max: e.hpMax,
            largeur: taille * 1.4,
            hauteur: widget.position == Position.avant ? 4 : 3,
            couleur: const Color(0xFFC0392B),
          ),

          // Nom
          Text(e.nom,
              style: TextStyle(
                  color: _dim,
                  fontSize: widget.position == Position.avant ? 8 : 7)),

          // Statuts
          if (e.effets.isNotEmpty)
            _MiniStatuts(effets: e.effets),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// DEMI-ÉCRAN HÉROS (bas)
// AVANT = haut de leur zone = grand
// ══════════════════════════════════════════════════════

class _DemiEcranHeros extends StatelessWidget {
  final List<CombattantCombat> heroes;
  final Animation<double> pulse;
  const _DemiEcranHeros({required this.heroes, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final avant   = heroes.where(
        (h) => h.position == Position.avant).toList();
    final milieu  = heroes.where(
        (h) => h.position == Position.milieu).toList();
    final arriere = heroes.where(
        (h) => h.position == Position.arriere).toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // AVANT — haut, grands (face aux ennemis)
        if (avant.isNotEmpty)
          _RangeeHeros(heroes: avant, position: Position.avant,
              pulse: pulse),

        // MILIEU
        if (milieu.isNotEmpty)
          _RangeeHeros(heroes: milieu, position: Position.milieu,
              pulse: pulse),

        // ARRIÈRE — bas, petits
        if (arriere.isNotEmpty)
          _RangeeHeros(heroes: arriere, position: Position.arriere,
              pulse: pulse),
      ],
    );
  }
}

class _RangeeHeros extends StatelessWidget {
  final List<CombattantCombat> heroes;
  final Position position;
  final Animation<double> pulse;
  const _RangeeHeros({
    required this.heroes, required this.position,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: heroes.map((h) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: _SpriteHeros(hero: h, position: position, pulse: pulse),
    )).toList(),
  );
}

// ── Sprite héros ──
class _SpriteHeros extends StatefulWidget {
  final CombattantCombat hero;
  final Position position;
  final Animation<double> pulse;
  const _SpriteHeros({
    required this.hero, required this.position,
    required this.pulse,
  });

  @override
  State<_SpriteHeros> createState() => _SpriteHerosState();
}

class _SpriteHerosState extends State<_SpriteHeros>
    with SingleTickerProviderStateMixin {
  late AnimationController _bob;
  late Animation<double> _bobAnim;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2200 +
          widget.hero.id.hashCode.abs() % 800),
    )..repeat(reverse: true);
    _bobAnim = Tween<double>(begin: 0, end: -4).animate(
        CurvedAnimation(parent: _bob, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h      = widget.hero;
    final taille = _tailleSprite(widget.position);
    final opacite = h.estAgenouille ? 0.14 :
        _opacitePosition(widget.position);

    // Ratio HP pour couleur
    final ratio = h.hpMaxCombat > 0
        ? h.hpCombat / h.hpMaxCombat : 0.0;
    final hpColor = ratio > 0.5
        ? const Color(0xFF27AE60)
        : ratio > 0.25
            ? const Color(0xFFC9A84C)
            : const Color(0xFFC0392B);

    return Opacity(
      opacity: opacite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Compagnon (coin gauche)
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Sprite principal
              AnimatedBuilder(
                animation: _bobAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0,
                      h.estAgenouille ? 0 : _bobAnim.value),
                  child: child,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Text(h.emoji,
                        style: TextStyle(
                            fontSize: taille,
                            shadows: [
                              Shadow(
                                color: _or.withOpacity(0.2),
                                blurRadius: 10,
                              ),
                            ])),
                    // Badge classe
                    Positioned(
                      bottom: -2, right: -6,
                      child: Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          color: _bg2,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                              color: _orDim.withOpacity(0.3),
                              width: 0.5),
                        ),
                        child: Center(
                          child: Text(h.badge,
                              style: const TextStyle(fontSize: 8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Compagnon
              if (h.compagnon != null && h.compagnon!.estActif)
                Positioned(
                  bottom: 0, left: -12,
                  child: Text(h.compagnon!.emoji,
                      style: const TextStyle(fontSize: 11)),
                ),
            ],
          ),

          const SizedBox(height: 3),

          // HP bar
          _HpBar(
            courant: h.hpCombat,
            max: h.hpMaxCombat,
            largeur: taille * 1.5,
            hauteur: 3,
            couleur: hpColor,
          ),

          // HP texte
          Text('${h.hpCombat}',
              style: TextStyle(
                  color: hpColor.withOpacity(0.8), fontSize: 8)),

          // Nom
          Text(h.nom,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: _dim,
                  fontSize: widget.position == Position.avant ? 8 : 7)),

          // Statuts
          if (h.effets.isNotEmpty)
            _MiniStatuts(effets: h.effets),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// COMPOSANTS COMMUNS
// ══════════════════════════════════════════════════════

class _HpBar extends StatelessWidget {
  final int courant, max;
  final double largeur, hauteur;
  final Color couleur;
  const _HpBar({
    required this.courant, required this.max,
    required this.largeur, required this.hauteur,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0
        ? (courant / max).clamp(0.0, 1.0) : 0.0;
    return Container(
      width: largeur,
      height: hauteur,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: ratio,
        child: Container(
          decoration: BoxDecoration(
            color: couleur,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _MiniStatuts extends StatelessWidget {
  final List<EffetStatut> effets;
  const _MiniStatuts({required this.effets});

  @override
  Widget build(BuildContext context) {
    final actifs = effets
        .where((e) => e.roundsRestants != 0)
        .take(3)
        .toList();
    if (actifs.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actifs.map((e) => Container(
        margin: const EdgeInsets.only(right: 2),
        width: 13, height: 13,
        decoration: BoxDecoration(
          color: _bg2,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: _border, width: 0.5),
        ),
        child: Center(
          child: Text(e.emoji,
              style: const TextStyle(fontSize: 7)),
        ),
      )).toList(),
    );
  }
}

// ── Overlay fin de combat ──
class _OverlayFin extends StatelessWidget {
  final bool victoire, fuite;
  const _OverlayFin({required this.victoire, required this.fuite});

  @override
  Widget build(BuildContext context) {
    final (emoji, label, couleur) = fuite
        ? ('🚪', 'RETRAITE', _dim)
        : victoire
            ? ('✦', 'VICTOIRE', const Color(0xFF27AE60))
            : ('💀', 'DÉFAITE', const Color(0xFFC0392B));

    return Positioned.fill(
      child: Container(
        color: _bg.withOpacity(0.6),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji,
                  style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      color: couleur,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3)),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// PANEL DE CONTRÔLE
// ══════════════════════════════════════════════════════

class _PanelControle extends StatelessWidget {
  final bool pause, fuiteInterdite;
  final int vitesse;
  final VoidCallback onPause, onPasser, onFuir;
  final void Function(int) onVitesse;

  const _PanelControle({
    required this.pause, required this.fuiteInterdite,
    required this.vitesse,
    required this.onPause, required this.onPasser,
    required this.onFuir, required this.onVitesse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12,
          MediaQuery.of(context).padding.bottom + 8),
      decoration: const BoxDecoration(
        color: Color(0xFF060402),
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          // Boutons principaux
          _BtnPanel(
            emoji: pause ? '▶' : '⏸',
            label: pause ? 'Reprendre' : 'Pause',
            onTap: onPause,
            actif: true,
          ),
          const SizedBox(width: 8),
          _BtnPanel(
            emoji: '⏭',
            label: 'Passer',
            onTap: onPasser,
            actif: pause,
          ),
          const SizedBox(width: 8),
          _BtnPanel(
            emoji: '🚪',
            label: 'Fuir',
            onTap: fuiteInterdite ? null : onFuir,
            actif: !fuiteInterdite,
            couleur: fuiteInterdite
                ? _dim
                : const Color(0xFFC0392B),
          ),

          // Divider
          Container(
            width: 1, height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: _border,
          ),

          // Vitesse
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('VITESSE',
                  style: TextStyle(
                      color: _dim, fontSize: 7,
                      letterSpacing: 1.2)),
              const SizedBox(height: 4),
              Row(
                children: [
                  for (final v in [1, 2, 3, 0])
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: GestureDetector(
                        onTap: () => onVitesse(v),
                        child: AnimatedContainer(
                          duration: const Duration(
                              milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: vitesse == v
                                ? _or.withOpacity(0.1)
                                : _bg3,
                            borderRadius:
                                BorderRadius.circular(3),
                            border: Border.all(
                              color: vitesse == v
                                  ? _orDim
                                  : _border,
                            ),
                          ),
                          child: Text(
                            v == 0 ? 'AUTO' : '×$v',
                            style: TextStyle(
                              color: vitesse == v
                                  ? _or : _dim,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BtnPanel extends StatelessWidget {
  final String emoji, label;
  final VoidCallback? onTap;
  final bool actif;
  final Color couleur;
  const _BtnPanel({
    required this.emoji, required this.label,
    required this.onTap, required this.actif,
    this.couleur = _dim,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: actif
            ? couleur.withOpacity(0.08)
            : _bg3,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: actif
              ? couleur.withOpacity(0.35)
              : _border,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji,
              style: TextStyle(
                  fontSize: 16,
                  color: actif
                      ? Colors.white
                      : Colors.white.withOpacity(0.25))),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: actif ? couleur : _dim,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
        ],
      ),
    ),
  );
}
