// lib/screens/zone/zone_screen.dart
// Sélection de zone et sous-zone
// Esthétique : carte de donjon sombre, zones révélées progressivement

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/etat_jeu.dart';
import '../../providers/game_provider.dart';
import '../../systems/progression_zones.dart';

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

// Données visuelles des zones
const _zonesData = [
  _ZoneData(
    numero: 1, nom: 'Chemin des Manants',
    emoji: '🌲', description: 'Gobelins affamés et bandits désespérés.',
    difficulte: 1, couleur: Color(0xFF27AE60),
  ),
  _ZoneData(
    numero: 2, nom: 'Forêt des Ombres',
    emoji: '🌑', description: 'Orcs belliqueux et loups sauvages.',
    difficulte: 2, couleur: Color(0xFF2ECC71),
  ),
  _ZoneData(
    numero: 3, nom: 'Marais Maudit',
    emoji: '☠️', description: 'Les morts marchent ici.',
    difficulte: 3, couleur: Color(0xFFF39C12),
  ),
  _ZoneData(
    numero: 4, nom: 'Mines Abandonnées',
    emoji: '⛏️', description: 'Trolls et araignées géantes dans l\'obscurité.',
    difficulte: 4, couleur: Color(0xFFE67E22),
  ),
  _ZoneData(
    numero: 5, nom: 'Citadelle en Ruine',
    emoji: '🏰', description: 'Le Prince des Vampires attend.',
    difficulte: 5, couleur: Color(0xFFE74C3C),
  ),
];

// Sous-zones par zone
const _souZonesData = {
  1: [
    _SouZoneData(id: '1-1', nom: 'Entrée du Chemin', emoji: '🛤️',
        ennemis: 'Gobelins ×2-3', estBoss: false),
    _SouZoneData(id: '1-2', nom: 'Campement Bandit', emoji: '⛺',
        ennemis: 'Bandits ×3-4', estBoss: false),
    _SouZoneData(id: '1-3', nom: 'Carrefour Maudit', emoji: '🔀',
        ennemis: 'Gobelins + Bandits', estBoss: false),
    _SouZoneData(id: '1-B', nom: 'Repaire du Roi Gobelin', emoji: '👑',
        ennemis: 'Roi Gobelin ⚡', estBoss: true),
  ],
  2: [
    _SouZoneData(id: '2-1', nom: 'Lisière de la Forêt', emoji: '🌲',
        ennemis: 'Gobelins + Loup', estBoss: false),
    _SouZoneData(id: '2-2', nom: 'Clairière Sombre', emoji: '🌿',
        ennemis: 'Orcs ×2-3', estBoss: false),
    _SouZoneData(id: '2-3', nom: 'Cœur de la Forêt', emoji: '🌳',
        ennemis: 'Orcs + Gobelins', estBoss: false),
    _SouZoneData(id: '2-B', nom: 'Trône du Seigneur Orc', emoji: '👹',
        ennemis: 'Seigneur Orc ⚡', estBoss: true),
  ],
  3: [
    _SouZoneData(id: '3-1', nom: 'Berges Pourries', emoji: '💧',
        ennemis: 'Squelettes ×3-4', estBoss: false),
    _SouZoneData(id: '3-2', nom: 'Village Abandonné', emoji: '🏚️',
        ennemis: 'Squelettes + Sorcier', estBoss: false),
    _SouZoneData(id: '3-3', nom: 'Cimetière', emoji: '🪦',
        ennemis: 'Squelettes + Sorciers', estBoss: false),
    _SouZoneData(id: '3-B', nom: 'Tour de l\'Archilliche', emoji: '💀',
        ennemis: 'Archilliche ⚡', estBoss: true),
  ],
  4: [
    _SouZoneData(id: '4-1', nom: 'Entrée des Mines', emoji: '🕳️',
        ennemis: 'Araignées ×3-5', estBoss: false),
    _SouZoneData(id: '4-2', nom: 'Galeries Profondes', emoji: '🪨',
        ennemis: 'Trolls + Araignées', estBoss: false),
    _SouZoneData(id: '4-3', nom: 'Salle des Profondeurs', emoji: '💎',
        ennemis: 'Trolls ×2-3 + Araignées', estBoss: false),
    _SouZoneData(id: '4-B', nom: 'Nid de la Reine', emoji: '🕷️',
        ennemis: 'Reine des Araignées ⚡', estBoss: true),
  ],
  5: [
    _SouZoneData(id: '5-1', nom: 'Courtine', emoji: '🧱',
        ennemis: 'Vampires + Squelettes', estBoss: false),
    _SouZoneData(id: '5-2', nom: 'Grande Salle', emoji: '🏛️',
        ennemis: 'Vampires + Sorciers', estBoss: false),
    _SouZoneData(id: '5-3', nom: 'Tour du Sang', emoji: '🗼',
        ennemis: 'Vampires ×3-5', estBoss: false),
    _SouZoneData(id: '5-B', nom: 'Chambre du Prince', emoji: '🧛',
        ennemis: 'Prince des Vampires ⚡', estBoss: true),
  ],
};

// ══════════════════════════════════════════════════════
// ÉCRAN SÉLECTION ZONE
// ══════════════════════════════════════════════════════

class ZoneScreen extends ConsumerStatefulWidget {
  final void Function(String souZoneId) onLancer;
  const ZoneScreen({super.key, required this.onLancer});

  @override
  ConsumerState<ZoneScreen> createState() => _ZoneScreenState();
}

class _ZoneScreenState extends ConsumerState<ZoneScreen> {
  int? _zoneSelectionnee;

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(gameProvider);
    if (etat == null) return const SizedBox.shrink();

    final completes = etat.souZonesCompletes;
    final zoneMax   = ProgressionZones.zoneMaxDebloquee(completes);

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _ZoneHeader(zoneMax: zoneMax),
          Expanded(
            child: Row(
              children: [
                // ── Colonne zones ──
                _ColonneZones(
                  zoneMax: zoneMax,
                  completes: completes,
                  selectionnee: _zoneSelectionnee,
                  onSelect: (n) => setState(() => _zoneSelectionnee = n),
                ),

                // ── Panneau sous-zones ──
                Expanded(
                  child: _zoneSelectionnee == null
                      ? _MessageChoix()
                      : _PanneauSousZones(
                          zone: _zonesData[_zoneSelectionnee! - 1],
                          completes: completes,
                          onLancer: widget.onLancer,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ──
class _ZoneHeader extends StatelessWidget {
  final int zoneMax;
  const _ZoneHeader({required this.zoneMax});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF060402),
        border: Border(bottom: BorderSide(color: _border)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 8, 16, 10),
      child: Row(
        children: [
          const Text('⚔️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CHOISIR UNE MISSION',
                    style: TextStyle(
                        color: _or, fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
                Text('Zone max débloquée : $zoneMax',
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
}

// ── Colonne des zones ──
class _ColonneZones extends StatelessWidget {
  final int zoneMax;
  final Set<String> completes;
  final int? selectionnee;
  final void Function(int) onSelect;
  const _ColonneZones({
    required this.zoneMax, required this.completes,
    required this.selectionnee, required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: _border)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 5,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: _border),
        itemBuilder: (_, i) {
          final z    = _zonesData[i];
          final lock = z.numero > zoneMax;
          final sel  = selectionnee == z.numero;
          final done = ProgressionZones.zoneComplete(z.numero, completes);

          return GestureDetector(
            onTap: lock ? null : () => onSelect(z.numero),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                color: sel
                    ? z.couleur.withOpacity(0.12)
                    : Colors.transparent,
                border: sel
                    ? Border(
                        right: BorderSide(
                            color: z.couleur, width: 2))
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    lock ? '🔒' : z.emoji,
                    style: TextStyle(
                        fontSize: 22,
                        color: lock
                            ? Colors.white.withOpacity(0.15)
                            : Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text('Z${z.numero}',
                      style: TextStyle(
                          color: lock
                              ? _dim.withOpacity(0.4)
                              : sel ? z.couleur : _dim,
                          fontSize: 9,
                          fontWeight: FontWeight.w700)),
                  if (done)
                    const Text('✓',
                        style: TextStyle(
                            color: Color(0xFF27AE60),
                            fontSize: 8)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Message de bienvenue ──
class _MessageChoix extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('🗺️', style: TextStyle(fontSize: 40)),
        SizedBox(height: 12),
        Text('Sélectionnez une zone',
            style: TextStyle(
                color: _dim, fontSize: 13,
                fontStyle: FontStyle.italic)),
      ],
    ),
  );
}

// ── Panneau sous-zones ──
class _PanneauSousZones extends StatelessWidget {
  final _ZoneData zone;
  final Set<String> completes;
  final void Function(String) onLancer;
  const _PanneauSousZones({
    required this.zone, required this.completes,
    required this.onLancer,
  });

  @override
  Widget build(BuildContext context) {
    final souZones = _souZonesData[zone.numero] ?? [];

    return Column(
      children: [
        // En-tête zone
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: zone.couleur.withOpacity(0.06),
            border: Border(
                bottom: BorderSide(
                    color: zone.couleur.withOpacity(0.2))),
          ),
          child: Row(
            children: [
              Text(zone.emoji,
                  style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(zone.nom,
                        style: const TextStyle(
                            color: _texte, fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(zone.description,
                        style: const TextStyle(
                            color: _dim, fontSize: 10,
                            fontStyle: FontStyle.italic)),
                    const SizedBox(height: 4),
                    _DifficulteBar(difficulte: zone.difficulte),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Liste sous-zones
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: souZones.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 6),
            itemBuilder: (_, i) {
              final sz = souZones[i];
              final debloquee = ProgressionZones.estDebloquee(
                  sz.id, completes);
              final complete = completes.contains(sz.id);

              return _CarteSouZone(
                souZone: sz,
                debloquee: debloquee,
                complete: complete,
                couleurZone: zone.couleur,
                onLancer: () => onLancer(sz.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Barre de difficulté ──
class _DifficulteBar extends StatelessWidget {
  final int difficulte;
  const _DifficulteBar({required this.difficulte});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Text('Difficulté ',
          style: TextStyle(color: _dim, fontSize: 9)),
      ...List.generate(5, (i) => Container(
        width: 10, height: 6,
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          color: i < difficulte
              ? _rouge.withOpacity(0.7 + i * 0.06)
              : _bg3,
          borderRadius: BorderRadius.circular(1),
          border: Border.all(
              color: i < difficulte
                  ? _rouge.withOpacity(0.4)
                  : _border,
              width: 0.5),
        ),
      )),
    ],
  );
}

// ── Carte sous-zone ──
class _CarteSouZone extends StatelessWidget {
  final _SouZoneData souZone;
  final bool debloquee, complete;
  final Color couleurZone;
  final VoidCallback onLancer;
  const _CarteSouZone({
    required this.souZone, required this.debloquee,
    required this.complete, required this.couleurZone,
    required this.onLancer,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: debloquee ? _bg3 : _bg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: souZone.estBoss
              ? (debloquee
                  ? _rouge.withOpacity(0.4)
                  : _border.withOpacity(0.3))
              : (debloquee ? _border : _border.withOpacity(0.3)),
          width: souZone.estBoss ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Emoji + indicateur
            Stack(
              clipBehavior: Clip.none,
              children: [
                Text(
                  debloquee ? souZone.emoji : '🔒',
                  style: TextStyle(
                      fontSize: 24,
                      color: debloquee
                          ? Colors.white
                          : Colors.white.withOpacity(0.2)),
                ),
                if (complete)
                  Positioned(
                    right: -4, top: -4,
                    child: Container(
                      width: 14, height: 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFF27AE60),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('✓',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          debloquee ? souZone.nom : '???',
                          style: TextStyle(
                              color: debloquee ? _texte : _dim,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (souZone.estBoss)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _rouge.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: _rouge.withOpacity(0.35),
                                width: 0.5),
                          ),
                          child: const Text('⚡ BOSS',
                              style: TextStyle(
                                  color: Color(0xFFE74C3C),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  if (debloquee) ...[
                    const SizedBox(height: 3),
                    Text(souZone.ennemis,
                        style: const TextStyle(
                            color: _dim, fontSize: 10,
                            fontStyle: FontStyle.italic)),
                  ],
                  if (!debloquee) ...[
                    const SizedBox(height: 3),
                    Text(
                      _prerequisLabel(souZone.id),
                      style: const TextStyle(
                          color: _dim, fontSize: 9,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),

            // Bouton lancer
            if (debloquee)
              GestureDetector(
                onTap: onLancer,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: souZone.estBoss
                        ? _rouge.withOpacity(0.12)
                        : couleurZone.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: souZone.estBoss
                          ? _rouge.withOpacity(0.4)
                          : couleurZone.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    souZone.estBoss ? '⚡' : '▶',
                    style: TextStyle(
                        color: souZone.estBoss
                            ? const Color(0xFFE74C3C)
                            : couleurZone,
                        fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _prerequisLabel(String id) {
    final parts = id.split('-');
    final zone  = parts[0];
    final etape = parts[1];
    switch (etape) {
      case '2': return 'Terminer $zone-1 pour débloquer';
      case '3': return 'Terminer $zone-2 pour débloquer';
      case 'B': return 'Terminer $zone-3 pour débloquer';
      default:  return 'Vaincre le boss précédent';
    }
  }
}

// ══════════════════════════════════════════════════════
// DATA CLASSES
// ══════════════════════════════════════════════════════

class _ZoneData {
  final int numero, difficulte;
  final String nom, emoji, description;
  final Color couleur;
  const _ZoneData({
    required this.numero, required this.nom,
    required this.emoji, required this.description,
    required this.difficulte, required this.couleur,
  });
}

class _SouZoneData {
  final String id, nom, emoji, ennemis;
  final bool estBoss;
  const _SouZoneData({
    required this.id, required this.nom,
    required this.emoji, required this.ennemis,
    required this.estBoss,
  });
}
