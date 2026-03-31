// lib/widgets/mise_a_jour_widget.dart
// Bannière de notification de mise à jour — non intrusive

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/data_loader.dart';
import '../data/remote_loader.dart';

// ── Provider pour l'état de mise à jour ──
final miseAJourProvider = StateNotifierProvider<MiseAJourStateNotifier, MiseAJourState>((ref) {
  return MiseAJourStateNotifier();
});

class MiseAJourState {
  final bool disponible;
  final bool enCours;
  final bool appliquee;
  final String message;

  const MiseAJourState({
    this.disponible = false,
    this.enCours = false,
    this.appliquee = false,
    this.message = '',
  });

  MiseAJourState copyWith({bool? disponible, bool? enCours, bool? appliquee, String? message}) =>
      MiseAJourState(
        disponible: disponible ?? this.disponible,
        enCours:    enCours    ?? this.enCours,
        appliquee:  appliquee  ?? this.appliquee,
        message:    message    ?? this.message,
      );
}

class MiseAJourStateNotifier extends StateNotifier<MiseAJourState> {
  MiseAJourStateNotifier() : super(const MiseAJourState());

  // Appelé au démarrage — vérifie en arrière-plan
  Future<void> verifier() async {
    final result = await RemoteLoader.verifierDisponibilite();
    if (result.miseAJour) {
      state = state.copyWith(
        disponible: true,
        message: result.message,
      );
    }
  }

  // Appelé quand le joueur clique "Mettre à jour"
  Future<void> appliquer() async {
    state = state.copyWith(enCours: true);
    await RemoteLoader.appliquerMiseAJour();
    await DataLoader.chargerTout(); // recharger depuis le cache
    state = state.copyWith(
      disponible: false,
      enCours: false,
      appliquee: true,
      message: 'Mise à jour installée ✓',
    );
    // Masquer la confirmation après 3 secondes
    await Future.delayed(const Duration(seconds: 3));
    state = state.copyWith(appliquee: false, message: '');
  }

  void ignorer() {
    state = state.copyWith(disponible: false);
  }
}

// ══════════════════════════════════════════════════════
// WIDGET — Bannière en bas de l'écran
// ══════════════════════════════════════════════════════
class MiseAJourBanner extends ConsumerWidget {
  const MiseAJourBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(miseAJourProvider);

    if (!etat.disponible && !etat.enCours && !etat.appliquee) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16130C),
        border: Border.all(
          color: etat.appliquee
              ? const Color(0xFF2D6A2D)
              : const Color(0xFFC9A84C),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: etat.appliquee
          ? _buildConfirmation()
          : etat.enCours
              ? _buildEnCours()
              : _buildDisponible(ref),
    );
  }

  Widget _buildDisponible(WidgetRef ref) {
    return Row(
      children: [
        const Text('📦', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MISE À JOUR DISPONIBLE',
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: Color(0xFFC9A84C),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Nouvelles classes et événements',
                style: TextStyle(fontSize: 11, color: Color(0xFF6B5A3A)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Bouton Plus tard
        GestureDetector(
          onTap: () => ref.read(miseAJourProvider.notifier).ignorer(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: const Text(
              'Plus tard',
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 9,
                color: Color(0xFF6B5A3A),
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        // Bouton Mettre à jour
        GestureDetector(
          onTap: () => ref.read(miseAJourProvider.notifier).appliquer(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1400),
              border: Border.all(color: const Color(0xFFC9A84C)),
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Text(
              'Installer',
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 9,
                color: Color(0xFFC9A84C),
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnCours() {
    return const Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFC9A84C),
          ),
        ),
        SizedBox(width: 12),
        Text(
          'Installation en cours...',
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 11,
            color: Color(0xFFC9A84C),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmation() {
    return const Row(
      children: [
        Text('✓', style: TextStyle(fontSize: 16, color: Color(0xFF2D6A2D))),
        SizedBox(width: 10),
        Text(
          'Mise à jour installée',
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 11,
            color: Color(0xFF2D6A2D),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════
// WRAPPER — à ajouter autour de l'écran principal
// ══════════════════════════════════════════════════════
class AvecVerificationMiseAJour extends ConsumerStatefulWidget {
  final Widget child;
  const AvecVerificationMiseAJour({super.key, required this.child});

  @override
  ConsumerState<AvecVerificationMiseAJour> createState() =>
      _AvecVerificationMiseAJourState();
}

class _AvecVerificationMiseAJourState
    extends ConsumerState<AvecVerificationMiseAJour> {
  @override
  void initState() {
    super.initState();
    // Vérifier en arrière-plan après 2s (laisse le jeu charger d'abord)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ref.read(miseAJourProvider.notifier).verifier();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: const MiseAJourBanner(),
        ),
      ],
    );
  }
}
