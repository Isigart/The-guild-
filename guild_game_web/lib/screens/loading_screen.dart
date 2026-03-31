// lib/screens/loading_screen.dart
// Écran de chargement — init SQLite + assets JSON

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';

// ══════════════════════════════════════════════════════
// CONSTANTES
// ══════════════════════════════════════════════════════

const _or    = Color(0xFFC9A84C);
const _orDim = Color(0xFF7A6030);
const _bg    = Color(0xFF050403);
const _dim   = Color(0xFF6B5A3A);

// ══════════════════════════════════════════════════════
// LOADING SCREEN
// ══════════════════════════════════════════════════════

class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() =>
      _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  String _etape = 'Initialisation...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(
            parent: _pulseCtrl, curve: Curves.easeInOut));

    _charger();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    final notifier = ref.read(gameProvider.notifier);

    _setEtape('Chargement des classes...', 0.15);
    await Future.delayed(const Duration(milliseconds: 200));

    _setEtape('Chargement des événements...', 0.35);
    await Future.delayed(const Duration(milliseconds: 200));

    _setEtape('Chargement des objets...', 0.55);
    await Future.delayed(const Duration(milliseconds: 200));

    _setEtape('Lecture de la sauvegarde...', 0.75);
    await notifier.initialiser();

    _setEtape('Prêt !', 1.0);
    await Future.delayed(const Duration(milliseconds: 400));
  }

  void _setEtape(String texte, double progress) {
    if (!mounted) return;
    setState(() {
      _etape    = texte;
      _progress = progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emblème animé
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Opacity(
                opacity: _pulse.value,
                child: const Text('⚜️',
                    style: TextStyle(fontSize: 52)),
              ),
            ),

            const SizedBox(height: 20),

            // Titre
            const Text('COMPAGNIE',
                style: TextStyle(
                    color: _or,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 5)),
            const Text('DE MERCENAIRES',
                style: TextStyle(
                    color: _orDim,
                    fontSize: 10,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w500)),

            const SizedBox(height: 48),

            // Barre de progression
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 60),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor:
                          Colors.white.withOpacity(0.05),
                      valueColor:
                          const AlwaysStoppedAnimation(_orDim),
                      minHeight: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(_etape,
                      style: const TextStyle(
                          color: _dim,
                          fontSize: 10,
                          fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
