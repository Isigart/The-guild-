// lib/systems/progression_zones.dart
// Progression des zones et sous-zones
// Déblocage naturel par les victoires

import '../models/etat_jeu.dart';
import '../models/models.dart';

class ProgressionZones {

  // ── XP par sous-zone ──
  static int xpPourSousZone(String souZoneId) {
    final parts = souZoneId.split('-');
    if (parts.length < 2) return 20;
    final zone  = int.tryParse(parts[0]) ?? 1;
    final isBoss = parts[1] == 'B';
    final baseXP = switch (zone) {
      1 =>  20, 2 =>  35, 3 =>  55,
      4 =>  80, 5 => 120, _ => 150,
    };
    return isBoss ? baseXP * 2 : baseXP;
  }

  // ── Seuil XP pour monter de niveau ──
  static int seuilXP(int niveauActuel) =>
      100 + (niveauActuel * 150);

  // ── Sous-zone suivante à débloquer ──
  static String? souZoneSuivante(String souZoneId) {
    final parts = souZoneId.split('-');
    if (parts.length < 2) return null;
    final zone = int.tryParse(parts[0]) ?? 1;
    final etape = parts[1];

    switch (etape) {
      case '1': return '$zone-2';
      case '2': return '$zone-3';
      case '3': return '$zone-B';
      case 'B':
        // Boss vaincu → débloquer zone suivante sous-zone 1
        final zoneNext = zone + 1;
        if (zoneNext > 5) return null;
        return '$zoneNext-1';
      default:  return null;
    }
  }

  // ── La sous-zone est-elle débloquée ? ──
  static bool estDebloquee(String souZoneId, Set<String> completes) {
    final parts = souZoneId.split('-');
    if (parts.length < 2) return false;
    final zone  = int.tryParse(parts[0]) ?? 1;
    final etape = parts[1];

    // Zone 1 sous-zone 1 toujours débloquée
    if (zone == 1 && etape == '1') return true;

    // Les autres zones nécessitent le boss précédent
    if (etape == '1' && zone > 1) {
      return completes.contains('${zone - 1}-B');
    }

    // Sous-zones 2, 3, B nécessitent la précédente
    final prerequis = switch (etape) {
      '2' => '$zone-1',
      '3' => '$zone-2',
      'B' => '$zone-3',
      _   => null,
    };
    return prerequis != null && completes.contains(prerequis);
  }

  // ── Appliquer une victoire ──
  // Retourne le nouvel état + la liste des nouvelles sous-zones débloquées
  static ({EtatJeu etat, List<String> nouvelles}) appliquerVictoire({
    required EtatJeu etat,
    required String souZoneId,
  }) {
    final completes = Set<String>.from(etat.souZonesCompletes)
      ..add(souZoneId);

    final nouvelles = <String>[];
    final suivante  = souZoneSuivante(souZoneId);
    if (suivante != null && !completes.contains(suivante)) {
      nouvelles.add(suivante);
    }

    final nouvelEtat = etat.copyWith(
      souZonesCompletes:   completes,
      derniereZoneVaincue: souZoneId,
      zoneSelectionneeId:  null,
    );

    return (etat: nouvelEtat, nouvelles: nouvelles);
  }

  // ── Liste des sous-zones disponibles pour une zone ──
  static List<String> souZonesDisponibles(int numeroZone, Set<String> completes) {
    final disponibles = <String>[];
    for (final etape in ['1', '2', '3', 'B']) {
      final id = '$numeroZone-$etape';
      if (estDebloquee(id, completes)) disponibles.add(id);
    }
    return disponibles;
  }

  // ── La zone entière est-elle complète (boss vaincu) ? ──
  static bool zoneComplete(int numeroZone, Set<String> completes) =>
      completes.contains('$numeroZone-B');

  // ── Zone max accessible ──
  static int zoneMaxDebloquee(Set<String> completes) {
    for (int z = 5; z >= 1; z--) {
      if (estDebloquee('$z-1', completes)) return z;
    }
    return 1;
  }
}
