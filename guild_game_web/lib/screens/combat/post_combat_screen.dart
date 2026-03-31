// lib/screens/combat/post_combat_screen.dart
// Écran post-combat — résultats, drops, XP, montée de niveau

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/combat_models.dart';
import '../../models/enums.dart';
import '../../models/objet.dart';
import '../../providers/game_provider.dart';
import '../../systems/progression_system.dart';

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

// ══════════════════════════════════════════════════════
// ÉCRAN POST-COMBAT
// ══════════════════════════════════════════════════════

class PostCombatScreen extends ConsumerStatefulWidget {
  final EtatCombat etatFinal;
  final String souZoneId;
  final List<EntreeCoffre> drops;
  final List<ChoixClasseInfo> choixClasse;
  final VoidCallback onRetour;

  const PostCombatScreen({
    super.key,
    required this.etatFinal,
    required this.souZoneId,
    required this.drops,
    required this.choixClasse,
    required this.onRetour,
  });

  @override
  ConsumerState<PostCombatScreen> createState() => _PostCombatScreenState();
}

class _PostCombatScreenState extends ConsumerState<PostCombatScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entree;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  // Index du choix de classe en cours (si plusieurs)
  int _choixEnCours = 0;

  @override
  void initState() {
    super.initState();
    _entree = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fade  = CurvedAnimation(parent: _entree, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entree, curve: Curves.easeOut));

    // Appliquer les drops au coffre
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.drops.isNotEmpty) {
        ref.read(gameProvider.notifier).appliquerDrops(widget.drops);
      }
    });
  }

  @override
  void dispose() {
    _entree.dispose();
    super.dispose();
  }

  bool get _aChoixClasse =>
      _choixEnCours < widget.choixClasse.length;

  @override
  Widget build(BuildContext context) {
    // Si choix de classe en attente → afficher d'abord
    if (_aChoixClasse) {
      return _EcranChoixClasse(
        info: widget.choixClasse[_choixEnCours],
        onChoisir: (classeId) {
          ref.read(gameProvider.notifier)
              .choisirClasse(widget.choixClasse[_choixEnCours].mercId,
                  classeId);
          setState(() => _choixEnCours++);
        },
      );
    }

    final etat      = widget.etatFinal;
    final victoire  = etat.victoire;
    final fuite     = etat.fuite;
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Column(
            children: [
              // Banner résultat
              _BannerResultat(
                  victoire: victoire, fuite: fuite,
                  ticks: etat.tick),

              // Contenu scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Récompenses (victoire seulement) ──
                      if (victoire) ...[
                        _SectionTitre('RÉCOMPENSES', '🏆'),
                        const SizedBox(height: 8),
                        _BlockRecompenses(
                          heroes: etat.heroes,
                          souZoneId: widget.souZoneId,
                          drops: widget.drops,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Mercenaires ──
                      _SectionTitre('MERCENAIRES', '⚔️'),
                      const SizedBox(height: 8),
                      ...etat.heroes.map((h) => _LigneMercenaire(
                        hero: h,
                        xpGagne: victoire
                            ? ProgressionZones_xpPour(widget.souZoneId)
                            : 0,
                      )),

                      // ── Drops objets ──
                      if (widget.drops.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _SectionTitre('BUTINS', '📦'),
                        const SizedBox(height: 8),
                        _BlockDrops(drops: widget.drops),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Bouton retour
              _BoutonRetour(onRetour: widget.onRetour),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper XP
int ProgressionZones_xpPour(String souZoneId) {
  final parts = souZoneId.split('-');
  final zone  = int.tryParse(parts[0]) ?? 1;
  final isBoss = parts[1] == 'B';
  final base = switch (zone) {
    1 => 20, 2 => 35, 3 => 55, 4 => 80, 5 => 120, _ => 150,
  };
  return isBoss ? base * 2 : base;
}

// ══════════════════════════════════════════════════════
// BANNER RÉSULTAT
// ══════════════════════════════════════════════════════

class _BannerResultat extends StatelessWidget {
  final bool victoire, fuite;
  final int ticks;
  const _BannerResultat({
    required this.victoire, required this.fuite,
    required this.ticks,
  });

  @override
  Widget build(BuildContext context) {
    final (emoji, label, bg, border) = fuite
        ? ('🚪', 'Retraite', const Color(0xFF181510),
           const Color(0xFF2A2415))
        : victoire
            ? ('✦', 'Victoire', const Color(0xFF0A1A0A),
               const Color(0xFF1A4A1A))
            : ('💀', 'Défaite', const Color(0xFF1A0A0A),
               const Color(0xFF4A1A1A));

    final couleur = fuite ? _dim
        : victoire ? _vert
        : _rouge;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 20, 20, 20),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Column(
        children: [
          Text(emoji,
              style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(label.toUpperCase(),
              style: TextStyle(
                  color: couleur,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3)),
          const SizedBox(height: 4),
          Text('$ticks rounds',
              style: const TextStyle(
                  color: _dim, fontSize: 11,
                  fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// BLOC RÉCOMPENSES
// ══════════════════════════════════════════════════════

class _BlockRecompenses extends StatelessWidget {
  final List<CombattantCombat> heroes;
  final String souZoneId;
  final List<EntreeCoffre> drops;
  const _BlockRecompenses({
    required this.heroes, required this.souZoneId,
    required this.drops,
  });

  @override
  Widget build(BuildContext context) {
    final zone   = int.tryParse(souZoneId.split('-')[0]) ?? 1;
    final isBoss = souZoneId.endsWith('B');
    final orBase = switch (zone) {
      1 => 15, 2 => 35, 3 => 65, 4 => 110, 5 => 165, _ => 20,
    };
    final or = isBoss ? orBase * 2 : orBase + 10;
    final ren = 10 + zone * 5 + (isBoss ? 20 : 0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _vert.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _vert.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _StatRecomp(
                  emoji: '🪙', label: 'Or', valeur: '+$or',
                  couleur: _or)),
              Expanded(child: _StatRecomp(
                  emoji: '⭐', label: 'Renommée', valeur: '+$ren',
                  couleur: const Color(0xFF8899FF))),
              Expanded(child: _StatRecomp(
                  emoji: '📦', label: 'Objets',
                  valeur: '×${drops.length}',
                  couleur: _texte)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRecomp extends StatelessWidget {
  final String emoji, label, valeur;
  final Color couleur;
  const _StatRecomp({
    required this.emoji, required this.label,
    required this.valeur, required this.couleur,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 4),
      Text(valeur,
          style: TextStyle(
              color: couleur, fontSize: 14,
              fontWeight: FontWeight.w800)),
      Text(label,
          style: const TextStyle(
              color: _dim, fontSize: 9)),
    ],
  );
}

// ══════════════════════════════════════════════════════
// LIGNE MERCENAIRE
// ══════════════════════════════════════════════════════

class _LigneMercenaire extends StatelessWidget {
  final CombattantCombat hero;
  final int xpGagne;
  const _LigneMercenaire({required this.hero, required this.xpGagne});

  @override
  Widget build(BuildContext context) {
    final m = hero.mercenaire;
    final xpCourant = m.xp;
    final xpSeuil   = 100 + m.niveau * 150;
    final xpRatio   = (xpCourant / xpSeuil).clamp(0.0, 1.0);
    final estATerre  = !hero.estVivant;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bg3,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: estATerre
              ? _rouge.withOpacity(0.3)
              : _border,
        ),
      ),
      child: Row(
        children: [
          // Sprite
          Text(m.classeActuelle.emoji,
              style: TextStyle(
                  fontSize: 22,
                  color: estATerre
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white)),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(m.nom,
                        style: const TextStyle(
                            color: _texte, fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Text('Niv.${m.niveau}',
                        style: const TextStyle(
                            color: _orDim, fontSize: 10)),
                    if (estATerre) ...[
                      const SizedBox(width: 6),
                      _BadgePetit(
                          label: '🩸 Blessé',
                          couleur: _rouge),
                    ],
                  ],
                ),
                const SizedBox(height: 4),

                // XP bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: xpRatio,
                          backgroundColor:
                              Colors.white.withOpacity(0.05),
                          valueColor:
                              const AlwaysStoppedAnimation(
                                  Color(0xFF27AE60)),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$xpCourant/$xpSeuil XP',
                        style: const TextStyle(
                            color: _dim, fontSize: 9)),
                  ],
                ),

                if (xpGagne > 0) ...[
                  const SizedBox(height: 2),
                  Text('+$xpGagne XP',
                      style: const TextStyle(
                          color: Color(0xFF58D68D),
                          fontSize: 9,
                          fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),

          // HP courant
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${hero.hpCombat}/${hero.hpMaxCombat}',
                  style: const TextStyle(
                      color: _dim, fontSize: 10)),
              const Text('HP',
                  style: TextStyle(color: _dim, fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgePetit extends StatelessWidget {
  final String label;
  final Color couleur;
  const _BadgePetit({required this.label, required this.couleur});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      color: couleur.withOpacity(0.1),
      borderRadius: BorderRadius.circular(3),
      border: Border.all(
          color: couleur.withOpacity(0.3),
          width: 0.5),
    ),
    child: Text(label,
        style: TextStyle(
            color: couleur, fontSize: 8,
            fontWeight: FontWeight.w600)),
  );
}

// ══════════════════════════════════════════════════════
// BLOC DROPS
// ══════════════════════════════════════════════════════

class _BlockDrops extends StatelessWidget {
  final List<EntreeCoffre> drops;
  const _BlockDrops({required this.drops});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: drops.map((d) => _ChipDrop(entree: d)).toList(),
    );
  }
}

class _ChipDrop extends StatelessWidget {
  final EntreeCoffre entree;
  const _ChipDrop({required this.entree});

  Color get _couleur {
    switch (entree.objet.qualite) {
      case QualiteObjet.commun:     return _dim;
      case QualiteObjet.rare:       return const Color(0xFF4169E1);
      case QualiteObjet.epique:     return const Color(0xFF8B008B);
      case QualiteObjet.legendaire: return _or;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: _couleur.withOpacity(0.08),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
          color: _couleur.withOpacity(0.3),
          width: 0.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(entree.objet.emoji,
            style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(entree.objet.nom,
                style: TextStyle(
                    color: _couleur, fontSize: 10,
                    fontWeight: FontWeight.w600)),
            Text('×${entree.quantite}',
                style: const TextStyle(
                    color: _dim, fontSize: 9)),
          ],
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════
// ÉCRAN CHOIX DE CLASSE
// ══════════════════════════════════════════════════════

class _EcranChoixClasse extends StatelessWidget {
  final ChoixClasseInfo info;
  final void Function(String classeId) onChoisir;
  const _EcranChoixClasse({
    required this.info, required this.onChoisir,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    body: Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.fromLTRB(
              16, MediaQuery.of(context).padding.top + 16,
              16, 16),
          decoration: const BoxDecoration(
            color: Color(0xFF060402),
            border: Border(
                bottom: BorderSide(color: _border))),
          child: Column(
            children: [
              const Text('🌟', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              const Text('ÉVOLUTION DE CLASSE',
                  style: TextStyle(
                      color: _or, fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2)),
              const SizedBox(height: 4),
              Text('${info.mercNom} peut évoluer — choisissez sa voie',
                  style: const TextStyle(
                      color: _dim, fontSize: 11,
                      fontStyle: FontStyle.italic)),
            ],
          ),
        ),

        // Options
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('CLASSES DISPONIBLES',
                  style: TextStyle(
                      color: _orDim, fontSize: 9,
                      letterSpacing: 2)),
              const SizedBox(height: 12),
              ...info.options.map((c) => _CarteChoixClasse(
                classe: c,
                onChoisir: () => onChoisir(c.id),
              )),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CarteChoixClasse extends StatelessWidget {
  final dynamic classe;
  final VoidCallback onChoisir;
  const _CarteChoixClasse({
    required this.classe, required this.onChoisir,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onChoisir,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bg3,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _orDim.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Text(classe.emoji,
              style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(classe.nom,
                    style: const TextStyle(
                        color: _texte, fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(classe.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _dim, fontSize: 10,
                        fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _or.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: _orDim.withOpacity(0.5)),
            ),
            child: const Text('Choisir',
                style: TextStyle(
                    color: _or, fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════
// SECTION TITRE + BOUTON RETOUR
// ══════════════════════════════════════════════════════

class _SectionTitre extends StatelessWidget {
  final String label, emoji;
  const _SectionTitre(this.label, this.emoji);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 13)),
      const SizedBox(width: 6),
      Text(label,
          style: const TextStyle(
              color: _orDim, fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 2)),
      Expanded(child: Container(
          height: 1,
          margin: const EdgeInsets.only(left: 8),
          color: _border)),
    ],
  );
}

class _BoutonRetour extends StatelessWidget {
  final VoidCallback onRetour;
  const _BoutonRetour({required this.onRetour});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
        16, 10, 16,
        MediaQuery.of(context).padding.bottom + 10),
    decoration: const BoxDecoration(
      color: Color(0xFF060402),
      border: Border(top: BorderSide(color: _border)),
    ),
    child: GestureDetector(
      onTap: onRetour,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _or.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _orDim.withOpacity(0.5)),
        ),
        child: const Center(
          child: Text('Retour à la guilde',
              style: TextStyle(
                  color: _or, fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
        ),
      ),
    ),
  );
}
