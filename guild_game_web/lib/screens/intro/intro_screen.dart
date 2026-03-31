// lib/screens/intro/intro_screen.dart
// Écran d'introduction — nouvelle partie
// Esthétique : parchemin brûlé, lettres d'or, ambiance médiévale sombre

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_provider.dart';
import '../../models/enums.dart';

// ══════════════════════════════════════════════════════
// CONSTANTES
// ══════════════════════════════════════════════════════

const _or       = Color(0xFFC9A84C);
const _orDim    = Color(0xFF7A6030);
const _orPale   = Color(0xFFE8D5A0);
const _bg       = Color(0xFF050403);
const _bg2      = Color(0xFF0A0805);
const _bg3      = Color(0xFF0F0D09);
const _border   = Color(0xFF2A2415);
const _texte    = Color(0xFFD4C49A);
const _dim      = Color(0xFF6B5A3A);
const _dimPale  = Color(0xFF8A7A5A);
const _rouge    = Color(0xFF8B1A1A);

// ══════════════════════════════════════════════════════
// DONNÉES — PREMIER MERCENAIRE
// ══════════════════════════════════════════════════════

const _premiersMercs = [
  _MercStartData(
    id: 'start_guerrier',
    classeId: 'guerrier',
    nom: 'Aldric',
    emoji: '⚔️',
    badge: '🗡️',
    titre: 'Guerrier',
    description: 'Force brute et endurance. '
        'Tient la ligne face à n\'importe quoi.',
    statPrimaire: 'FOR',
    valeurStat: 8,
    couleur: Color(0xFFB03A2E),
  ),
  _MercStartData(
    id: 'start_rodeur',
    classeId: 'rodeur',
    nom: 'Sylvara',
    emoji: '🏹',
    badge: '🐺',
    titre: 'Rôdeur',
    description: 'Rapide et précise. '
        'Son loup ne la quitte jamais.',
    statPrimaire: 'AGI',
    valeurStat: 9,
    couleur: Color(0xFF27AE60),
  ),
  _MercStartData(
    id: 'start_filou',
    classeId: 'filou',
    nom: 'Korvin',
    emoji: '🗡️',
    badge: '🐀',
    titre: 'Filou',
    description: 'Imprévisible et chanceux. '
        'Frappe dans l\'ombre.',
    statPrimaire: 'CHA',
    valeurStat: 9,
    couleur: Color(0xFF7D3C98),
  ),
];

// ══════════════════════════════════════════════════════
// ÉCRAN INTRO — MACHINE À ÉTATS
// ══════════════════════════════════════════════════════

class IntroScreen extends ConsumerStatefulWidget {
  final VoidCallback onTermine;
  const IntroScreen({super.key, required this.onTermine});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen>
    with TickerProviderStateMixin {

  int _etape = 0; // 0=splash 1=histoire 2=nom 3=merc 4=fin
  int _pageLore = 0;

  String _nomGuilde = '';
  _MercStartData? _mercChoisi;

  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fade = CurvedAnimation(
        parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _allerA(int etape) {
    _fadeCtrl.reverse().then((_) {
      setState(() => _etape = etape);
      _fadeCtrl.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fade,
        child: _construireEtape(),
      ),
    );
  }

  Widget _construireEtape() {
    switch (_etape) {
      case 0:  return _EcranSplash(onContinuer: () => _allerA(1));
      case 1:  return _EcranLore(
                 page: _pageLore,
                 onPage: (p) => setState(() => _pageLore = p),
                 onContinuer: () => _allerA(2),
               );
      case 2:  return _EcranNomGuilde(
                 onContinuer: (nom) {
                   setState(() => _nomGuilde = nom);
                   _allerA(3);
                 },
               );
      case 3:  return _EcranChoixMerc(
                 onChoisir: (merc) {
                   setState(() => _mercChoisi = merc);
                   _allerA(4);
                 },
               );
      case 4:  return _EcranCPartis(
                 nomGuilde: _nomGuilde,
                 merc: _mercChoisi!,
                 onLancer: _lancer,
               );
      default: return const SizedBox.shrink();
    }
  }

  void _lancer() {
    final notifier = ref.read(gameProvider.notifier);
    notifier.nouvellePartie(
      nomGuilde: _nomGuilde,
      premierMercId: _mercChoisi!.id,
      premierMercClasseId: _mercChoisi!.classeId,
      premierMercNom: _mercChoisi!.nom,
    );
    widget.onTermine();
  }
}

// ══════════════════════════════════════════════════════
// ÉTAPE 0 — SPLASH
// ══════════════════════════════════════════════════════

class _EcranSplash extends StatefulWidget {
  final VoidCallback onContinuer;
  const _EcranSplash({required this.onContinuer});

  @override
  State<_EcranSplash> createState() => _EcranSplashState();
}

class _EcranSplashState extends State<_EcranSplash>
    with TickerProviderStateMixin {
  late AnimationController _titrCtrl;
  late AnimationController _subCtrl;
  late AnimationController _btnCtrl;
  late AnimationController _particlesCtrl;

  @override
  void initState() {
    super.initState();

    _titrCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400))
      ..forward();

    _subCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800));

    _btnCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600));

    _particlesCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 4000))
      ..repeat();

    Future.delayed(const Duration(milliseconds: 1600),
        () => _subCtrl.forward());
    Future.delayed(const Duration(milliseconds: 2600),
        () => _btnCtrl.forward());
  }

  @override
  void dispose() {
    _titrCtrl.dispose();
    _subCtrl.dispose();
    _btnCtrl.dispose();
    _particlesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Particules flottantes
        AnimatedBuilder(
          animation: _particlesCtrl,
          builder: (_, __) => CustomPaint(
            size: Size.infinite,
            painter: _ParticlesPainter(_particlesCtrl.value),
          ),
        ),

        // Contenu centré
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emblème
              AnimatedBuilder(
                animation: _titrCtrl,
                builder: (_, __) => Opacity(
                  opacity: _titrCtrl.value,
                  child: Transform.scale(
                    scale: 0.7 + _titrCtrl.value * 0.3,
                    child: const Text('⚜️',
                        style: TextStyle(fontSize: 56)),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Titre principal — lettre par lettre
              AnimatedBuilder(
                animation: _titrCtrl,
                builder: (_, __) {
                  final pct = _titrCtrl.value;
                  const titre = 'COMPAGNIE';
                  final visible = (pct * titre.length).round()
                      .clamp(0, titre.length);
                  return Column(
                    children: [
                      Text(
                        titre.substring(0, visible),
                        style: const TextStyle(
                          color: _or,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'DE MERCENAIRES',
                        style: TextStyle(
                          color: _orDim.withOpacity(
                              (pct * 3 - 2).clamp(0.0, 1.0)),
                          fontSize: 13,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Séparateur
              AnimatedBuilder(
                animation: _subCtrl,
                builder: (_, __) => Opacity(
                  opacity: _subCtrl.value,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LineSep(width: 40 * _subCtrl.value),
                      const SizedBox(width: 10),
                      Text('✦',
                          style: TextStyle(
                              color: _orDim, fontSize: 12)),
                      const SizedBox(width: 10),
                      _LineSep(width: 40 * _subCtrl.value),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Sous-titre
              AnimatedBuilder(
                animation: _subCtrl,
                builder: (_, __) => Opacity(
                  opacity: _subCtrl.value,
                  child: Text(
                    'Reconstruisez ce qui fut grand',
                    style: TextStyle(
                      color: _dimPale.withOpacity(0.8),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // Bouton commencer
              AnimatedBuilder(
                animation: _btnCtrl,
                builder: (_, __) => Opacity(
                  opacity: _btnCtrl.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _btnCtrl.value)),
                    child: _BoutonIntro(
                      label: 'COMMENCER',
                      onTap: widget.onContinuer,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LineSep extends StatelessWidget {
  final double width;
  const _LineSep({required this.width});

  @override
  Widget build(BuildContext context) => Container(
    width: width, height: 1,
    color: _orDim.withOpacity(0.4),
  );
}

// Painter particules flottantes
class _ParticlesPainter extends CustomPainter {
  final double t;
  final _rng = Random(42);
  _ParticlesPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 24;
    for (int i = 0; i < n; i++) {
      final seed  = i * 137.508;
      final x     = (seed % size.width);
      final speed = 0.3 + (i % 5) * 0.15;
      final y     = size.height -
          ((t * speed * size.height + i * 73.0) % size.height);
      final opacite = (0.03 + (i % 4) * 0.015)
          .clamp(0.0, 0.12);

      final paint = Paint()
        ..color = _or.withOpacity(opacite)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(x, y), 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter o) => o.t != t;
}

// ══════════════════════════════════════════════════════
// ÉTAPE 1 — LORE
// ══════════════════════════════════════════════════════

const _lore = [
  _LorePage(
    emoji: '🏚️',
    titre: 'Les ruines',
    texte: 'La grande guilde est tombée il y a dix ans. '
        'Guerre, trahison, mauvaise gestion — les raisons importent peu. '
        'Ce qui reste : des murs noircis, un bureau de recrutement '
        'qui tient encore debout, et vous.',
  ),
  _LorePage(
    emoji: '⚔️',
    titre: 'L\'héritage',
    texte: 'Vous avez récupéré le sceau de la guilde dans les décombres. '
        'Les anciens membres vous regardent. Les marchands attendent. '
        'La région a besoin d\'une compagnie digne de ce nom. '
        'Allez-vous répondre à l\'appel ?',
  ),
  _LorePage(
    emoji: '✦',
    titre: 'Votre destin',
    texte: 'Recrutez, entraînez, explorez. '
        'Reconstruisez bâtiment par bâtiment. '
        'Affrontez les zones qui entourent la ville. '
        'Faites en sorte que le nom de votre guilde '
        'résonne jusqu\'aux confins du royaume.',
  ),
];

class _EcranLore extends StatelessWidget {
  final int page;
  final void Function(int) onPage;
  final VoidCallback onContinuer;
  const _EcranLore({
    required this.page, required this.onPage,
    required this.onContinuer,
  });

  @override
  Widget build(BuildContext context) {
    final p = _lore[page];
    final derniere = page == _lore.length - 1;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Spacer(),

          // Emblème de page
          Text(p.emoji,
              style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 24),

          // Titre
          Text(p.titre,
              style: const TextStyle(
                  color: _or, fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2)),
          const SizedBox(height: 20),

          // Texte
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _bg2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            child: Text(
              p.texte,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _texte, fontSize: 13,
                  height: 1.8,
                  fontStyle: FontStyle.italic),
            ),
          ),

          const Spacer(),

          // Indicateurs de page
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_lore.length, (i) =>
              GestureDetector(
                onTap: () => onPage(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == page ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == page
                        ? _or : _orDim.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              )
            ),
          ),
          const SizedBox(height: 28),

          // Bouton
          _BoutonIntro(
            label: derniere ? 'FONDER MA GUILDE' : 'SUIVANT',
            onTap: derniere
                ? onContinuer
                : () => onPage(page + 1),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// ÉTAPE 2 — NOM DE GUILDE
// ══════════════════════════════════════════════════════

class _EcranNomGuilde extends StatefulWidget {
  final void Function(String) onContinuer;
  const _EcranNomGuilde({required this.onContinuer});

  @override
  State<_EcranNomGuilde> createState() => _EcranNomGuildeState();
}

class _EcranNomGuildeState extends State<_EcranNomGuilde> {
  final _ctrl = TextEditingController();
  bool _valide = false;

  static const _suggestions = [
    'Les Crocs d\'Acier',
    'L\'Ordre du Corbeau',
    'Les Fils du Destin',
    'La Flamme Éternelle',
    'Les Ombres de l\'Aube',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      setState(() => _valide = _ctrl.text.trim().length >= 3);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 32,
          24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          const Text('⚜️',
              style: TextStyle(fontSize: 28)),
          const SizedBox(height: 12),
          const Text('BAPTISEZ VOTRE GUILDE',
              style: TextStyle(
                  color: _or, fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2)),
          const SizedBox(height: 6),
          const Text(
              'Ce nom sera gravé dans l\'histoire.',
              style: TextStyle(
                  color: _dim, fontSize: 12,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 28),

          // Champ de saisie
          Container(
            decoration: BoxDecoration(
              color: _bg3,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _valide
                    ? _orDim.withOpacity(0.6)
                    : _border,
              ),
            ),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              maxLength: 30,
              style: const TextStyle(
                  color: _texte,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Nom de la guilde...',
                hintStyle: TextStyle(
                    color: _dim.withOpacity(0.5),
                    fontSize: 15),
                counterStyle: const TextStyle(
                    color: _dim, fontSize: 10),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Suggestions
          const Text('SUGGESTIONS',
              style: TextStyle(
                  color: _orDim, fontSize: 9,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _suggestions.map((s) =>
              GestureDetector(
                onTap: () {
                  _ctrl.text = s;
                  _ctrl.selection = TextSelection.collapsed(
                      offset: s.length);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _bg3,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: _border),
                  ),
                  child: Text(s,
                      style: const TextStyle(
                          color: _dimPale,
                          fontSize: 10)),
                ),
              )
            ).toList(),
          ),

          const Spacer(),

          _BoutonIntro(
            label: 'CONTINUER',
            actif: _valide,
            onTap: _valide
                ? () => widget.onContinuer(_ctrl.text.trim())
                : null,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// ÉTAPE 3 — CHOIX DU PREMIER MERCENAIRE
// ══════════════════════════════════════════════════════

class _EcranChoixMerc extends StatefulWidget {
  final void Function(_MercStartData) onChoisir;
  const _EcranChoixMerc({required this.onChoisir});

  @override
  State<_EcranChoixMerc> createState() => _EcranChoixMercState();
}

class _EcranChoixMercState extends State<_EcranChoixMerc> {
  _MercStartData? _selectionne;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 24,
          20, 24),
      child: Column(
        children: [
          // Titre
          const Text('VOTRE PREMIER MERCENAIRE',
              style: TextStyle(
                  color: _or, fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2)),
          const SizedBox(height: 4),
          const Text('Il vous accompagnera depuis le début.',
              style: TextStyle(
                  color: _dim, fontSize: 11,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 20),

          // Cartes mercenaires
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _premiersMercs.map((m) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CarteMercDebut(
                    data: m,
                    selectionne: _selectionne?.id == m.id,
                    onTap: () => setState(
                        () => _selectionne = m),
                  ),
                )
              ).toList(),
            ),
          ),

          const SizedBox(height: 12),

          _BoutonIntro(
            label: 'C\'EST PARTI',
            actif: _selectionne != null,
            onTap: _selectionne != null
                ? () => widget.onChoisir(_selectionne!)
                : null,
          ),
        ],
      ),
    );
  }
}

class _CarteMercDebut extends StatelessWidget {
  final _MercStartData data;
  final bool selectionne;
  final VoidCallback onTap;
  const _CarteMercDebut({
    required this.data, required this.selectionne,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selectionne
            ? data.couleur.withOpacity(0.10)
            : _bg3,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selectionne
              ? data.couleur.withOpacity(0.6)
              : _border,
          width: selectionne ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Sprite
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: data.couleur.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: data.couleur.withOpacity(0.2)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(data.emoji,
                    style: const TextStyle(fontSize: 28)),
                Positioned(
                  bottom: 2, right: 2,
                  child: Text(data.badge,
                      style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(data.nom,
                        style: const TextStyle(
                            color: _texte, fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: data.couleur.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(data.titre,
                          style: TextStyle(
                              color: data.couleur,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(data.description,
                    style: const TextStyle(
                        color: _dim, fontSize: 10,
                        height: 1.4,
                        fontStyle: FontStyle.italic)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('${data.statPrimaire}  ',
                        style: TextStyle(
                            color: data.couleur,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                    ...List.generate(10, (i) => Container(
                      width: 8, height: 8,
                      margin: const EdgeInsets.only(right: 2),
                      decoration: BoxDecoration(
                        color: i < data.valeurStat
                            ? data.couleur
                            : data.couleur.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    )),
                  ],
                ),
              ],
            ),
          ),

          // Check
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: selectionne
                  ? data.couleur
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: selectionne
                    ? data.couleur
                    : _border,
              ),
            ),
            child: selectionne
                ? const Icon(Icons.check,
                    size: 14, color: Colors.white)
                : null,
          ),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════
// ÉTAPE 4 — C'EST PARTI
// ══════════════════════════════════════════════════════

class _EcranCPartis extends StatefulWidget {
  final String nomGuilde;
  final _MercStartData merc;
  final VoidCallback onLancer;
  const _EcranCPartis({
    required this.nomGuilde, required this.merc,
    required this.onLancer,
  });

  @override
  State<_EcranCPartis> createState() => _EcranCPartisState();
}

class _EcranCPartisState extends State<_EcranCPartis>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: _scale,
          child: const Text('⚜️',
              style: TextStyle(fontSize: 60)),
        ),
        const SizedBox(height: 24),

        Text(widget.nomGuilde.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: _or, fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 3)),
        const SizedBox(height: 8),
        Text(
            'fondée par ${widget.merc.nom} le ${widget.merc.titre}',
            style: const TextStyle(
                color: _dim, fontSize: 12,
                fontStyle: FontStyle.italic)),

        const SizedBox(height: 40),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _bg2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              Text(widget.merc.emoji,
                  style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 10),
              Text('${widget.merc.nom}, ${widget.merc.titre}',
                  style: const TextStyle(
                      color: _texte, fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Votre premier mercenaire vous attend.',
                  style: const TextStyle(
                      color: _dim, fontSize: 11,
                      fontStyle: FontStyle.italic)),
            ],
          ),
        ),

        const SizedBox(height: 48),

        _BoutonIntro(
          label: 'ENTRER DANS LA GUILDE',
          onTap: widget.onLancer,
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════
// COMPOSANTS COMMUNS
// ══════════════════════════════════════════════════════

class _BoutonIntro extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool actif;
  const _BoutonIntro({
    required this.label,
    this.onTap,
    this.actif = true,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: actif ? onTap : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: actif
            ? _or.withOpacity(0.08)
            : _bg3,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: actif
              ? _orDim.withOpacity(0.5)
              : _border,
        ),
      ),
      child: Center(
        child: Text(label,
            style: TextStyle(
                color: actif ? _or : _dim,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════
// DATA CLASSES
// ══════════════════════════════════════════════════════

class _MercStartData {
  final String id, classeId, nom, emoji, badge, titre, description;
  final String statPrimaire;
  final int valeurStat;
  final Color couleur;
  const _MercStartData({
    required this.id, required this.classeId,
    required this.nom, required this.emoji,
    required this.badge, required this.titre,
    required this.description, required this.statPrimaire,
    required this.valeurStat, required this.couleur,
  });
}

class _LorePage {
  final String emoji, titre, texte;
  const _LorePage({
    required this.emoji, required this.titre,
    required this.texte,
  });
}
