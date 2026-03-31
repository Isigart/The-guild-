// lib/screens/guild/guild_screen.dart
// Plan de guilde + UI bâtiment par tap
// Esthétique : sombre médiéval, parchemin usé, or mat

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../models/enums.dart';
import '../../models/mercenaire.dart';
import '../../models/objet.dart';
import '../../providers/game_provider.dart';

// ══════════════════════════════════════════════════════
// CONSTANTES VISUELLES
// ══════════════════════════════════════════════════════

const _or       = Color(0xFFC9A84C);
const _orDim    = Color(0xFF7A6030);
const _bg       = Color(0xFF0A0805);
const _bg2      = Color(0xFF0F0D09);
const _bg3      = Color(0xFF181510);
const _border   = Color(0xFF2A2415);
const _texte    = Color(0xFFD4C49A);
const _dim      = Color(0xFF6B5A3A);
const _rouge    = Color(0xFF8B1A1A);
const _vert     = Color(0xFF1A4A1A);

// ══════════════════════════════════════════════════════
// ÉCRAN PLAN DE GUILDE
// ══════════════════════════════════════════════════════

class GuildScreen extends ConsumerWidget {
  const GuildScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(gameProvider);
    if (etat == null) return const SizedBox.shrink();

    final batiments = etat.batiments;
    final decouverts = batiments.where((b) => b.estDecouvert).toList();
    final inconnus   = batiments.where((b) => !b.estDecouvert).length;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── Header ──
          _GuildHeader(
            nomGuilde: etat.nomGuilde,
            jour:      etat.jour,
            or:        etat.or,
            renommee:  etat.renommee,
          ),

          // ── Plan ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section bâtiments découverts
                  _SectionTitre(label: 'GUILDE', emoji: '🏰',
                      count: decouverts.length),
                  const SizedBox(height: 8),
                  _GrilleBatiments(
                    batiments: decouverts,
                    onTap: (bat) => _ouvrirBatiment(context, bat, ref),
                  ),

                  // Section ruines inconnues
                  if (inconnus > 0) ...[
                    const SizedBox(height: 20),
                    _SectionTitre(label: 'RUINES INCONNUES',
                        emoji: '🌫️', count: inconnus),
                    const SizedBox(height: 8),
                    _RuinesInconnues(count: inconnus),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _ouvrirBatiment(BuildContext ctx, Batiment bat, WidgetRef ref) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(ctx),
        child: _BatimentSheet(batiment: bat),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// HEADER GUILDE
// ══════════════════════════════════════════════════════

class _GuildHeader extends StatelessWidget {
  final String nomGuilde;
  final int jour, or, renommee;
  const _GuildHeader({
    required this.nomGuilde,
    required this.jour,
    required this.or,
    required this.renommee,
  });

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nomGuilde,
                    style: const TextStyle(
                        color: _or, fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
                const SizedBox(height: 2),
                Text('Jour $jour',
                    style: const TextStyle(
                        color: _dim, fontSize: 11,
                        fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          _StatPill(emoji: '🪙', valeur: or.toString(), couleur: _or),
          const SizedBox(width: 8),
          _StatPill(emoji: '⭐', valeur: renommee.toString(),
              couleur: const Color(0xFF8899FF)),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String emoji, valeur;
  final Color couleur;
  const _StatPill({required this.emoji, required this.valeur,
      required this.couleur});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: couleur.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: couleur.withOpacity(0.25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(valeur,
            style: TextStyle(color: couleur, fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════
// SECTION TITRE
// ══════════════════════════════════════════════════════

class _SectionTitre extends StatelessWidget {
  final String label, emoji;
  final int count;
  const _SectionTitre({required this.label, required this.emoji,
      required this.count});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 6),
      Text(label,
          style: const TextStyle(
              color: _orDim, fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0)),
      const SizedBox(width: 8),
      Container(
        width: 20, height: 20,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _or.withOpacity(0.12),
            border: Border.all(color: _orDim.withOpacity(0.4))),
        child: Center(
          child: Text('$count',
              style: const TextStyle(
                  color: _orDim, fontSize: 9,
                  fontWeight: FontWeight.w700)),
        ),
      ),
      Expanded(child: Container(
          height: 1,
          margin: const EdgeInsets.only(left: 8),
          color: _border)),
    ],
  );
}

// ══════════════════════════════════════════════════════
// GRILLE DES BÂTIMENTS
// ══════════════════════════════════════════════════════

class _GrilleBatiments extends StatelessWidget {
  final List<Batiment> batiments;
  final void Function(Batiment) onTap;
  const _GrilleBatiments({required this.batiments, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: batiments.length,
      itemBuilder: (_, i) => _CarteBatiment(
        batiment: batiments[i],
        onTap: () => onTap(batiments[i]),
      ),
    );
  }
}

// ── Carte bâtiment individuelle ──
class _CarteBatiment extends StatelessWidget {
  final Batiment batiment;
  final VoidCallback onTap;
  const _CarteBatiment({required this.batiment, required this.onTap});

  Color get _couleurEtat {
    switch (batiment.etat) {
      case BatimentEtat.intact:    return _vert;
      case BatimentEtat.endommage: return const Color(0xFF7A5010);
      case BatimentEtat.detruit:   return _rouge;
    }
  }

  String get _labelEtat {
    switch (batiment.etat) {
      case BatimentEtat.intact:    return 'N${batiment.niveau}';
      case BatimentEtat.endommage: return '⚠ Endommagé';
      case BatimentEtat.detruit:   return '💀 Détruit';
    }
  }

  @override
  Widget build(BuildContext context) {
    final actif = batiment.estFonctionnel;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _bg3,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: actif ? _border : _couleurEtat.withOpacity(0.4),
            width: actif ? 1 : 1.5,
          ),
        ),
        child: Stack(
          children: [
            // Overlay état
            if (!actif)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: _couleurEtat.withOpacity(0.06),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Emoji
                  Text(batiment.type.emoji,
                      style: TextStyle(
                          fontSize: 28,
                          color: actif
                              ? Colors.white
                              : Colors.white.withOpacity(0.4))),
                  const SizedBox(height: 6),

                  // Nom
                  Text(
                    batiment.type.nom,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: actif ? _texte : _dim,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),

                  // Badge état
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _couleurEtat.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: _couleurEtat.withOpacity(0.35),
                          width: 0.5),
                    ),
                    child: Text(_labelEtat,
                        style: TextStyle(
                            color: _couleurEtat.withOpacity(0.9),
                            fontSize: 8,
                            fontWeight: FontWeight.w700)),
                  ),

                  // Civils assignés
                  if (batiment.mercsAssignesIds.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('👤 ×${batiment.mercsAssignesIds.length}',
                        style: const TextStyle(
                            color: _orDim, fontSize: 8)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ruines inconnues ──
class _RuinesInconnues extends StatelessWidget {
  final int count;
  const _RuinesInconnues({required this.count});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: count,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: _bg3.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: _border.withOpacity(0.4),
              style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🌫️',
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.white.withOpacity(0.2))),
            const SizedBox(height: 6),
            Text('???',
                style: TextStyle(
                    color: _dim.withOpacity(0.5),
                    fontSize: 9,
                    letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// BOTTOM SHEET — UI BÂTIMENT
// ══════════════════════════════════════════════════════

class _BatimentSheet extends ConsumerStatefulWidget {
  final Batiment batiment;
  const _BatimentSheet({required this.batiment});

  @override
  ConsumerState<_BatimentSheet> createState() => _BatimentSheetState();
}

class _BatimentSheetState extends ConsumerState<_BatimentSheet> {
  bool _chargement = false;

  Batiment get bat => widget.batiment;

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(gameProvider);
    if (etat == null) return const SizedBox.shrink();

    final civils = etat.mercenaires
        .where((m) => bat.mercsAssignesIds.contains(m.id))
        .toList();
    final disponibles = etat.mercenaires
        .where((m) => m.estDisponible &&
            !bat.mercsAssignesIds.contains(m.id))
        .toList();

    // Recette pour amélioration
    final recette = ref.read(gameProvider.notifier)
        .objetsRequisPour(bat.id, bat.niveau);
    final orRequis = ref.read(gameProvider.notifier)
        .orRequisPour(bat.id, bat.niveau);
    final manquants = ref.read(gameProvider.notifier)
        .ingredientsManquants(bat.id, bat.niveau);
    final peutAmeliorer = ref.read(gameProvider.notifier)
        .peutConstruire(recette) && etat.or >= orRequis;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0C0A06),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(
              top: BorderSide(color: _border),
              left: BorderSide(color: _border),
              right: BorderSide(color: _border)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [

            // ── Poignée ──
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36, height: 3,
                decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // ── En-tête ──
            _SheetHeader(batiment: bat),
            const SizedBox(height: 16),

            // ── État et actions ──
            if (!bat.estFonctionnel)
              _BlockEtat(
                batiment: bat,
                orDisponible: etat.or,
                onReparer: _reparer,
                chargement: _chargement,
              ),

            // ── Civils assignés ──
            if (bat.estFonctionnel) ...[
              const SizedBox(height: 4),
              _SectionTitre(label: 'CIVILS ASSIGNÉS',
                  emoji: '👤', count: civils.length),
              const SizedBox(height: 8),
              if (civils.isEmpty)
                _MessageVide(texte: 'Aucun civil assigné à ce poste.')
              else
                ...civils.map((m) => _LigneCivil(
                    mercenaire: m,
                    onRetirer: () => _retirerMerc(m.id))),

              // Ajouter un civil
              if (!bat.estPlein && disponibles.isNotEmpty) ...[
                const SizedBox(height: 8),
                _BoutonAjouter(
                  disponibles: disponibles,
                  onAjouter: (id) => _assignerMerc(id),
                ),
              ],

              const SizedBox(height: 20),

              // ── Amélioration ──
              _SectionTitre(label: 'AMÉLIORATION',
                  emoji: '⬆️', count: bat.niveau),
              const SizedBox(height: 8),
              if (recette.isEmpty)
                _MessageVide(texte: 'Niveau maximum atteint.')
              else
                _BlockAmelioration(
                  batiment: bat,
                  recette: recette,
                  orRequis: orRequis,
                  orDisponible: etat.or,
                  manquants: manquants,
                  peutAmeliorer: peutAmeliorer,
                  onAmeliorer: _ameliorer,
                  chargement: _chargement,
                  coffre: etat.coffreGuilde,
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _reparer() async {
    setState(() => _chargement = true);
    ref.read(gameProvider.notifier).reparer(bat.id);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _chargement = false);
  }

  void _assignerMerc(String mercId) {
    ref.read(gameProvider.notifier).assignerMerc(mercId, bat.id);
    setState(() {});
  }

  void _retirerMerc(String mercId) {
    ref.read(gameProvider.notifier).retirerMerc(mercId);
    setState(() {});
  }

  void _ameliorer() async {
    setState(() => _chargement = true);
    ref.read(gameProvider.notifier).ameliorerBatiment(bat.id, bat.niveau);
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _chargement = false);
  }
}

// ── En-tête du sheet ──
class _SheetHeader extends StatelessWidget {
  final Batiment batiment;
  const _SheetHeader({required this.batiment});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: _bg3,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Center(
            child: Text(batiment.type.emoji,
                style: const TextStyle(fontSize: 28)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(batiment.type.nom,
                  style: const TextStyle(
                      color: _texte, fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
              const SizedBox(height: 3),
              Row(
                children: [
                  _BadgeNiveau(batiment.niveau),
                  const SizedBox(width: 6),
                  _BadgeEtat(batiment.etat),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BadgeNiveau extends StatelessWidget {
  final int niveau;
  const _BadgeNiveau(this.niveau);
  @override
  Widget build(BuildContext context) => _Badge(
    label: 'Niveau $niveau',
    bg: _or.withOpacity(0.1),
    border: _orDim.withOpacity(0.4),
    texte: _orDim,
  );
}

class _BadgeEtat extends StatelessWidget {
  final BatimentEtat etat;
  const _BadgeEtat(this.etat);

  String get label {
    switch (etat) {
      case BatimentEtat.intact:    return '✅ Intact';
      case BatimentEtat.endommage: return '⚠️ Endommagé';
      case BatimentEtat.detruit:   return '💀 Détruit';
    }
  }

  Color get couleur {
    switch (etat) {
      case BatimentEtat.intact:    return const Color(0xFF27AE60);
      case BatimentEtat.endommage: return const Color(0xFFC9A84C);
      case BatimentEtat.detruit:   return const Color(0xFFC0392B);
    }
  }

  @override
  Widget build(BuildContext context) => _Badge(
    label: label,
    bg: couleur.withOpacity(0.1),
    border: couleur.withOpacity(0.35),
    texte: couleur,
  );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg, border, texte;
  const _Badge({required this.label, required this.bg,
      required this.border, required this.texte});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: border, width: 0.5),
    ),
    child: Text(label,
        style: TextStyle(color: texte, fontSize: 10,
            fontWeight: FontWeight.w600)),
  );
}

// ── Block état + réparation ──
class _BlockEtat extends StatelessWidget {
  final Batiment batiment;
  final int orDisponible;
  final VoidCallback onReparer;
  final bool chargement;
  const _BlockEtat({
    required this.batiment, required this.orDisponible,
    required this.onReparer, required this.chargement,
  });

  @override
  Widget build(BuildContext context) {
    final cout = batiment.coutReparation;
    final peutReparer = orDisponible >= cout;
    final isDetruit = batiment.etat == BatimentEtat.detruit;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _rouge.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _rouge.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isDetruit
                ? '💀 Bâtiment détruit — reconstruction requise'
                : '⚠️ Bâtiment endommagé — réparation nécessaire',
            style: TextStyle(
                color: _rouge.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  isDetruit
                      ? 'Reconstruit à neuf depuis les fondations.'
                      : 'Réparer pour rendre le bâtiment fonctionnel.',
                  style: const TextStyle(color: _dim, fontSize: 11),
                ),
              ),
              const SizedBox(width: 12),
              _BoutonAction(
                label: isDetruit ? 'Reconstruire' : 'Réparer',
                sous: '🪙 $cout or',
                actif: peutReparer && !chargement,
                couleur: peutReparer ? _or : _dim,
                onTap: peutReparer ? onReparer : null,
                chargement: chargement,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Ligne civil ──
class _LigneCivil extends StatelessWidget {
  final Mercenaire mercenaire;
  final VoidCallback onRetirer;
  const _LigneCivil({required this.mercenaire, required this.onRetirer});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: _bg3,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: _border),
    ),
    child: Row(
      children: [
        Text(mercenaire.classeActuelle.emoji,
            style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mercenaire.nom,
                  style: const TextStyle(color: _texte, fontSize: 12,
                      fontWeight: FontWeight.w600)),
              Text(mercenaire.classeActuelle.nom,
                  style: const TextStyle(color: _dim, fontSize: 10)),
            ],
          ),
        ),
        GestureDetector(
          onTap: onRetirer,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _rouge.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _rouge.withOpacity(0.3)),
            ),
            child: const Text('✕',
                style: TextStyle(color: Color(0xFFE74C3C), fontSize: 11)),
          ),
        ),
      ],
    ),
  );
}

// ── Bouton ajouter civil ──
class _BoutonAjouter extends StatelessWidget {
  final List<Mercenaire> disponibles;
  final void Function(String) onAjouter;
  const _BoutonAjouter({required this.disponibles, required this.onAjouter});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => _afficherChoix(context),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: _or.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: _orDim.withOpacity(0.3),
            style: BorderStyle.solid),
      ),
      child: const Center(
        child: Text('+ Assigner un civil',
            style: TextStyle(color: _orDim, fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      ),
    ),
  );

  void _afficherChoix(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: _bg2,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (_) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const Center(
            child: Text('Choisir un civil',
                style: TextStyle(color: _or, fontSize: 13,
                    fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
          const SizedBox(height: 12),
          ...disponibles.map((m) => GestureDetector(
            onTap: () {
              Navigator.pop(ctx);
              onAjouter(m.id);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _bg3,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Text(m.classeActuelle.emoji,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.nom,
                            style: const TextStyle(
                                color: _texte, fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        Text(m.classeActuelle.nom,
                            style: const TextStyle(
                                color: _dim, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}

// ── Block amélioration ──
class _BlockAmelioration extends StatelessWidget {
  final Batiment batiment;
  final Map<String, int> recette, manquants;
  final int orRequis, orDisponible;
  final bool peutAmeliorer, chargement;
  final VoidCallback onAmeliorer;
  final CoffreGuilde coffre;

  const _BlockAmelioration({
    required this.batiment, required this.recette,
    required this.orRequis, required this.orDisponible,
    required this.manquants, required this.peutAmeliorer,
    required this.onAmeliorer, required this.chargement,
    required this.coffre,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bg3,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('N${batiment.niveau} → N${batiment.niveau + 1}',
                  style: const TextStyle(
                      color: _or, fontSize: 12,
                      fontWeight: FontWeight.w700)),
              Text('🪙 $orRequis or',
                  style: TextStyle(
                      color: orDisponible >= orRequis ? _or : _rouge,
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          const Text('MATÉRIAUX REQUIS',
              style: TextStyle(color: _dim, fontSize: 9,
                  letterSpacing: 1.5)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: recette.entries.map((e) {
              final dispo  = coffre.quantiteDe(e.key);
              final manque = manquants.containsKey(e.key);
              return _ChipRessource(
                objetId: e.key,
                requis: e.value,
                possede: dispo,
                manque: manque,
              );
            }).toList(),
          ),

          if (manquants.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _rouge.withOpacity(0.06),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _rouge.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Text('🗺️ ',
                      style: TextStyle(fontSize: 11)),
                  Expanded(
                    child: Text(
                      'Il manque ${manquants.length} ressource(s). '
                      'Explorez les zones pour les obtenir.',
                      style: const TextStyle(
                          color: _dim, fontSize: 10,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          _BoutonAction(
            label: 'Améliorer',
            sous: peutAmeliorer ? 'Prêt !' : 'Ressources insuffisantes',
            actif: peutAmeliorer && !chargement,
            couleur: peutAmeliorer ? _or : _dim,
            onTap: peutAmeliorer ? onAmeliorer : null,
            chargement: chargement,
            pleineLargeur: true,
          ),
        ],
      ),
    );
  }
}

class _ChipRessource extends StatelessWidget {
  final String objetId;
  final int requis, possede;
  final bool manque;
  const _ChipRessource({
    required this.objetId, required this.requis,
    required this.possede, required this.manque,
  });

  // Emoji par ressource
  String get emoji {
    const map = {
      'debris_bois': '🪵', 'eclat_pierre': '🪨',
      'vieux_parchemin': '📜', 'herbe_medicinale': '🌿',
      'minerai_commun': '⛏️', 'bois_robuste': '🌳',
      'cristal_soin': '💎', 'encre_runique': '🖊️',
      'pierre_rare': '💠', 'minerai_rare': '🔩',
      'soie_araignee': '🕸️', 'essence_magique': '✨',
      'os_dragon': '🦴', 'coeur_vampire': '🫀',
      'fragment_liche': '💀', 'acier_noir': '⚫',
      'cristal_ancien': '🔮',
    };
    return map[objetId] ?? '📦';
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: manque
          ? _rouge.withOpacity(0.08)
          : _vert.withOpacity(0.08),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(
        color: manque
            ? _rouge.withOpacity(0.3)
            : const Color(0xFF27AE60).withOpacity(0.3),
        width: 0.5,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 4),
        Text('$possede/$requis',
            style: TextStyle(
                color: manque
                    ? const Color(0xFFE74C3C)
                    : const Color(0xFF27AE60),
                fontSize: 10,
                fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

// ── Bouton action ──
class _BoutonAction extends StatelessWidget {
  final String label, sous;
  final bool actif, chargement;
  final bool pleineLargeur;
  final Color couleur;
  final VoidCallback? onTap;
  const _BoutonAction({
    required this.label, required this.sous,
    required this.actif, required this.couleur,
    required this.onTap, required this.chargement,
    this.pleineLargeur = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget btn = GestureDetector(
      onTap: actif ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: pleineLargeur ? double.infinity : null,
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: actif
              ? couleur.withOpacity(0.1)
              : _bg3,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: actif
                ? couleur.withOpacity(0.5)
                : _border,
          ),
        ),
        child: chargement
            ? Center(
                child: SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: couleur,
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: actif ? couleur : _dim,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),
                  Text(sous,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: actif
                              ? couleur.withOpacity(0.6)
                              : _dim.withOpacity(0.5),
                          fontSize: 9)),
                ],
              ),
      ),
    );
    return btn;
  }
}

// ── Message vide ──
class _MessageVide extends StatelessWidget {
  final String texte;
  const _MessageVide({required this.texte});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(texte,
        style: const TextStyle(
            color: _dim, fontSize: 11,
            fontStyle: FontStyle.italic)),
  );
}
