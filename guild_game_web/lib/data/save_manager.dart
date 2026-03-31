// lib/data/save_manager.dart
// Sauvegarde automatique — déclenchée après chaque action importante

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';

// Points de sauvegarde automatique
enum SaveTrigger {
  finJournee,       // Fin de journée → sauvegarde complète
  combatTermine,    // Après un combat
  statDistribuee,   // Après distribution d'un point de stat
  batimentAchete,   // Après achat d'un bâtiment
  mercAssigne,      // Après assignation au poste
  nouvellePartie,   // Après création d'une partie
}

class SaveManager {
  static const Set<SaveTrigger> _triggersAutomatiques = {
    SaveTrigger.finJournee,
    SaveTrigger.combatTermine,
    SaveTrigger.batimentAchete,
    SaveTrigger.nouvellePartie,
  };

  static bool _enCours = false;

  // Déclencher une sauvegarde selon le contexte
  static Future<void> declencherSi(
    SaveTrigger trigger,
    WidgetRef ref,
  ) async {
    if (!_triggersAutomatiques.contains(trigger)) return;
    if (_enCours) return;

    _enCours = true;
    try {
      await ref.read(gameProvider.notifier).sauvegarder();
    } finally {
      _enCours = false;
    }
  }

  // Sauvegarde manuelle explicite
  static Future<void> sauvegarderMaintenant(WidgetRef ref) async {
    if (_enCours) return;
    _enCours = true;
    try {
      await ref.read(gameProvider.notifier).sauvegarder();
    } finally {
      _enCours = false;
    }
  }
}

// Provider pour l'état de sauvegarde (affichage UI)
final sauvegardeEnCoursProvider = StateProvider<bool>((ref) => false);
