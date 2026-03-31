// lib/screens/main_screen.dart
// Navigation principale — bottom nav + flux de jeu complet
// Guilde → Zone → Combat → Post-combat → Événements → Guilde

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/combat_models.dart';
import '../models/objet.dart';
import '../providers/game_provider.dart';
import '../systems/progression_system.dart';
import 'guild/guild_screen.dart';
import 'zone/zone_screen.dart';
import 'combat/combat_screen.dart';
import 'combat/post_combat_screen.dart';
import 'evenement/evenement_popup.dart';
import 'coffre/coffre_screen.dart';
import 'mercenaires/mercenaires_screen.dart';
import 'intro/intro_screen.dart';
import 'journal/journal_screen.dart';

// ══════════════════════════════════════════════════════
// CONSTANTES
// ══════════════════════════════════════════════════════

const _or     = Color(0xFFC9A84C);
const _orDim  = Color(0xFF7A6030);
const _bg     = Color(0xFF0A0805);
const _border = Color(0xFF2A2415);
const _dim    = Color(0xFF6B5A3A);

// ══════════════════════════════════════════════════════
// NAVIGATION PRINCIPALE
// ══════════════════════════════════════════════════════

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _onglet = 0;

  // Flux de combat
  String?      _souZoneEnCours;
  EtatCombat?  _etatCombatFinal;
  List<EntreeCoffre>     _dropsCombat  = [];
  List<ChoixClasseInfo>  _choixClasse  = [];

  // Phase du flux
  _Phase _phase = _Phase.navigation;

  @override
  Widget build(BuildContext context) {
    // ── Flux combat ──
    if (_phase == _Phase.combat && _souZoneEnCours != null) {
      final etat = ref.read(gameProvider);
      if (etat == null) return _erreur();
      final etatCombat = ref.read(gameProvider.notifier)
          .initialiserCombat(etat);

      return CombatScreen(
        etatInitial: etatCombat,
        souZoneId:   _souZoneEnCours!,
        fuiteInterdite: etat.fuiteInterdite,
        onFin: _onCombatFini,
      );
    }

    if (_phase == _Phase.postCombat && _etatCombatFinal != null) {
      return PostCombatScreen(
        etatFinal:   _etatCombatFinal!,
        souZoneId:   _souZoneEnCours!,
        drops:       _dropsCombat,
        choixClasse: _choixClasse,
        onRetour:    _onRetourGuilde,
      );
    }

    // ── Navigation normale ──
    return Scaffold(
      backgroundColor: _bg,
      body: IndexedStack(
        index: _onglet,
        children: [
          // 0 — Guilde
          const GuildScreen(),

          // 1 — Zones
          ZoneScreen(onLancer: _lancerCombat),

          // 2 — Coffre
          CoffreScreen(
            onDetonateur: _onDetonateur,
          ),

          // 3 — Journal
          const JournalScreen(),

          // 4 — Mercenaires
          const MercenairesScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        onglet: _onglet,
        onChange: (i) => setState(() => _onglet = i),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // FLUX DE COMBAT
  // ══════════════════════════════════════════════════════

  void _lancerCombat(String souZoneId) {
    setState(() {
      _souZoneEnCours = souZoneId;
      _phase = _Phase.combat;
    });
  }

  void _onCombatFini(EtatCombat etatFinal) async {
    final notifier = ref.read(gameProvider.notifier);

    // Calculer les drops
    final drops = etatFinal.victoire
        ? notifier.calculerDropsCombat(
            zoneId:   'zone_${_souZoneEnCours!.split('-')[0]}',
            souZoneId: _souZoneEnCours!,
            estBoss:  _souZoneEnCours!.endsWith('B'),
          )
        : <EntreeCoffre>[];

    // Appliquer le résultat (XP, zones, blessures)
    final vicResult = notifier.appliquerResultatCombat(
        etatFinal, souZoneId: _souZoneEnCours);

    setState(() {
      _etatCombatFinal = etatFinal;
      _dropsCombat     = drops;
      _choixClasse     = vicResult?.choixClasse ?? [];
      _phase           = _Phase.postCombat;
    });
  }

  void _onRetourGuilde() async {
    setState(() => _phase = _Phase.navigation);

    // Sélectionner les événements du jour
    final etat = ref.read(gameProvider);
    if (etat == null || !mounted) return;

    final evenements = ref.read(gameProvider.notifier)
        .selectionnerEvenementsJour(
          zoneVaincrueAujourdhui: _etatCombatFinal?.victoire == true
              ? _souZoneEnCours : null,
        );

    // Afficher les popups événements
    if (evenements.isNotEmpty && mounted) {
      await afficherEvenements(
        context: context,
        evenements: evenements,
        etat: etat,
        ref: ref,
      );
    }

    // Reset
    setState(() {
      _souZoneEnCours  = null;
      _etatCombatFinal = null;
      _dropsCombat     = [];
      _choixClasse     = [];
      _onglet          = 0; // Retour à la guilde
    });
  }

  void _onDetonateur(String evenementId) async {
    final etat = ref.read(gameProvider);
    if (etat == null || !mounted) return;

    final notifier  = ref.read(gameProvider.notifier);
    final evenement = notifier.tousLesEvenements
        .firstWhere((e) => e.id == evenementId,
            orElse: () => notifier.tousLesEvenements.first);

    await afficherEvenements(
      context: context,
      evenements: [evenement],
      etat: etat,
      ref: ref,
    );
  }

  Widget _erreur() => const Scaffold(
    backgroundColor: _bg,
    body: Center(
      child: Text('Erreur — état du jeu manquant',
          style: TextStyle(color: Colors.red)),
    ),
  );
}

// ══════════════════════════════════════════════════════
// BOTTOM NAVIGATION
// ══════════════════════════════════════════════════════

class _BottomNav extends StatelessWidget {
  final int onglet;
  final void Function(int) onChange;
  const _BottomNav({required this.onglet, required this.onChange});

  static const _items = [
    _NavItem(emoji: '🏰', label: 'Guilde'),
    _NavItem(emoji: '⚔️', label: 'Zones'),
    _NavItem(emoji: '📦', label: 'Coffre'),
    _NavItem(emoji: '📖', label: 'Journal'),
    _NavItem(emoji: '⚔️', label: 'Équipe'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Color(0xFF060402),
      border: Border(top: BorderSide(color: _border)),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 58,
        child: Row(
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            final actif = onglet == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChange(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: actif
                            ? _orDim.withOpacity(0.6)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.emoji,
                          style: TextStyle(
                              fontSize: 18,
                              color: actif
                                  ? Colors.white
                                  : Colors.white
                                      .withOpacity(0.3))),
                      const SizedBox(height: 2),
                      Text(item.label,
                          style: TextStyle(
                              color: actif ? _or : _dim,
                              fontSize: 9,
                              fontWeight: actif
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    ),
  );
}

class _NavItem {
  final String emoji, label;
  const _NavItem({required this.emoji, required this.label});
}

// ══════════════════════════════════════════════════════
// PHASE DU FLUX
// ══════════════════════════════════════════════════════

enum _Phase { navigation, combat, postCombat }
