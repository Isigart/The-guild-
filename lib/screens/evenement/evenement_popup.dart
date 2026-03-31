// lib/screens/evenement/evenement_popup.dart
// Popup modal pour les événements — un à la fois
// Appelé après le combat avec la liste des événements du jour

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/etat_jeu.dart';
import '../../systems/evenement_system.dart';
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
const _rouge  = Color(0xFFC0392B);
const _vert   = Color(0xFF27AE60);

// ══════════════════════════════════════════════════════
// AFFICHER LES ÉVÉNEMENTS EN SÉQUENCE
// Appelé depuis le provider après le combat
// ══════════════════════════════════════════════════════

Future<void> afficherEvenements({
  required BuildContext context,
  required List<Evenement> evenements,
  required EtatJeu etat,
  required WidgetRef ref,
}) async {
  for (final ev in evenements) {
    if (!context.mounted) break;
    await showEvenementPopup(
      context: context,
      evenement: ev,
      etat: etat,
      ref: ref,
    );
  }
}

// ══════════════════════════════════════════════════════
// POPUP INDIVIDUEL
// ══════════════════════════════════════════════════════

Future<void> showEvenementPopup({
  required BuildContext context,
  required Evenement evenement,
  required EtatJeu etat,
  required WidgetRef ref,
}) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black87,
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (_, anim, __, child) => ScaleTransition(
      scale: CurvedAnimation(
          parent: anim, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: anim, child: child),
    ),
    pageBuilder: (_, __, ___) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: _EvenementDialog(
        evenement: evenement,
        etat: etat,
        ref: ref,
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════
// DIALOG PRINCIPAL
// ══════════════════════════════════════════════════════

class _EvenementDialog extends ConsumerStatefulWidget {
  final Evenement evenement;
  final EtatJeu etat;
  final WidgetRef ref;
  const _EvenementDialog({
    required this.evenement,
    required this.etat,
    required this.ref,
  });

  @override
  ConsumerState<_EvenementDialog> createState() =>
      _EvenementDialogState();
}

class _EvenementDialogState
    extends ConsumerState<_EvenementDialog> {
  // Phase : 'choix' → 'resultat'
  String _phase = 'choix';
  ResultatEvenement? _resultat;
  String? _choixSelectionne;

  Evenement get ev => widget.evenement;

  // Catégorie → couleur d'accent
  Color get _couleurCategorie {
    switch (ev.categorie) {
      case 'progression': return _or;
      case 'metier':      return const Color(0xFF4169E1);
      case 'aleatoire':   return _texte;
      default:            return _dim;
    }
  }

  String get _labelCategorie {
    switch (ev.categorie) {
      case 'progression': return '📖 QUÊTE';
      case 'metier':      return '⚒️ MÉTIER';
      case 'aleatoire':   return '🎲 ALÉATOIRE';
      default:            return '📜 ÉVÉNEMENT';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 60),
      child: Container(
        decoration: BoxDecoration(
          color: _bg2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _couleurCategorie.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: _couleurCategorie.withOpacity(0.08),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _DialogHeader(
              emoji: ev.emoji,
              titre: ev.titre,
              categorie: _labelCategorie,
              couleur: _couleurCategorie,
            ),

            // Corps
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    18, 0, 18, 18),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // Texte narratif
                    _TexteNarratif(
                      texte: ref
                          .read(gameProvider.notifier)
                          .formaterTexteEvenement(ev.texte),
                    ),

                    const SizedBox(height: 16),

                    // Phase choix ou résultat
                    if (_phase == 'choix')
                      _PhaseChoix(
                        evenement: ev,
                        etat: widget.etat,
                        onChoisir: _resoudre,
                        onPasser: _passerSansChoix,
                      )
                    else if (_resultat != null)
                      _PhaseResultat(
                        resultat: _resultat!,
                        onFermer: _fermer,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Résoudre avec un choix ──
  void _resoudre(String? choixId) {
    final notifier = ref.read(gameProvider.notifier);
    final resultat = notifier.resoudreEvenement(
      evenement: ev,
      choixId: choixId,
    );

    // Appliquer les conséquences
    notifier.appliquerResultatEvenement(
      resultat, ev.id, choixId: choixId);

    setState(() {
      _resultat = resultat;
      _choixSelectionne = choixId;
      _phase = 'resultat';
    });
  }

  // ── Passer (événement sans choix) ──
  void _passerSansChoix() => _resoudre(null);

  // ── Fermer le dialog ──
  void _fermer() => Navigator.of(context).pop();
}

// ══════════════════════════════════════════════════════
// HEADER DU DIALOG
// ══════════════════════════════════════════════════════

class _DialogHeader extends StatelessWidget {
  final String emoji, titre, categorie;
  final Color couleur;
  const _DialogHeader({
    required this.emoji, required this.titre,
    required this.categorie, required this.couleur,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
    decoration: BoxDecoration(
      color: couleur.withOpacity(0.04),
      borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12)),
      border: Border(
          bottom: BorderSide(
              color: couleur.withOpacity(0.15))),
    ),
    child: Row(
      children: [
        Text(emoji,
            style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre,
                  style: const TextStyle(
                      color: _texte,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(categorie,
                  style: TextStyle(
                      color: couleur.withOpacity(0.7),
                      fontSize: 9,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════
// TEXTE NARRATIF
// ══════════════════════════════════════════════════════

class _TexteNarratif extends StatelessWidget {
  final String texte;
  const _TexteNarratif({required this.texte});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _bg3,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: _border),
    ),
    child: Text(
      texte,
      style: const TextStyle(
          color: _texte,
          fontSize: 12,
          height: 1.6,
          fontStyle: FontStyle.italic),
    ),
  );
}

// ══════════════════════════════════════════════════════
// PHASE CHOIX
// ══════════════════════════════════════════════════════

class _PhaseChoix extends StatelessWidget {
  final Evenement evenement;
  final EtatJeu etat;
  final void Function(String?) onChoisir;
  final VoidCallback onPasser;
  const _PhaseChoix({
    required this.evenement, required this.etat,
    required this.onChoisir, required this.onPasser,
  });

  @override
  Widget build(BuildContext context) {
    final ev = evenement;

    // Événement avec choix
    if (ev.aDesChoix) {
      final choixVisibles = ev.choix.where((c) {
        // Vérifier conditionVisible basique
        final cond = c.conditionVisible;
        if (cond == null) return true;
        if (cond['orMin'] != null &&
            etat.or < (cond['orMin'] as num).toInt()) return false;
        return true;
      }).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('QUE FAITES-VOUS ?',
              style: TextStyle(
                  color: _orDim, fontSize: 9,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...choixVisibles.map((c) => _BoutonChoix(
            choix: c,
            onTap: () => onChoisir(c.id),
          )),
        ],
      );
    }

    // Événement avec check automatique — juste un bouton "Voir"
    return _BoutonPrimaire(
      label: 'Voir le résultat',
      onTap: onPasser,
    );
  }
}

class _BoutonChoix extends StatelessWidget {
  final ChoixEvenement choix;
  final VoidCallback onTap;
  const _BoutonChoix({required this.choix, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _bg3,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(choix.texte,
                style: const TextStyle(
                    color: _texte, fontSize: 12)),
          ),
          // Indicateur check
          if (choix.check != null)
            _BadgeCheck(check: choix.check!),
        ],
      ),
    ),
  );
}

class _BadgeCheck extends StatelessWidget {
  final Map<String, dynamic> check;
  const _BadgeCheck({required this.check});

  @override
  Widget build(BuildContext context) {
    final type  = check['stat'] as String? ??
        check['substat'] as String? ?? '?';
    final seuil = check['seuil'] as int? ?? 0;
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(
          horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _orDim.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
            color: _orDim.withOpacity(0.3), width: 0.5),
      ),
      child: Text('$type $seuil+',
          style: const TextStyle(
              color: _orDim, fontSize: 8,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _BoutonPrimaire extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _BoutonPrimaire({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: _or.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: _orDim.withOpacity(0.4)),
      ),
      child: Center(
        child: Text(label,
            style: const TextStyle(
                color: _or, fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════
// PHASE RÉSULTAT
// ══════════════════════════════════════════════════════

class _PhaseResultat extends StatelessWidget {
  final ResultatEvenement resultat;
  final VoidCallback onFermer;
  const _PhaseResultat({
    required this.resultat, required this.onFermer,
  });

  @override
  Widget build(BuildContext context) {
    final cons = resultat.consequences;
    final texte = resultat.texteAffiche;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Texte résultat
        if (texte.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: resultat.estSucces
                  ? _vert.withOpacity(0.06)
                  : _rouge.withOpacity(0.06),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: resultat.estSucces
                    ? _vert.withOpacity(0.2)
                    : _rouge.withOpacity(0.2),
              ),
            ),
            child: Text(texte,
                style: TextStyle(
                    color: resultat.estSucces
                        ? const Color(0xFF58D68D)
                        : const Color(0xFFE74C3C),
                    fontSize: 12,
                    height: 1.5)),
          ),
          const SizedBox(height: 10),
        ],

        // Conséquences visuelles
        Wrap(
          spacing: 6, runSpacing: 6,
          children: _construireChips(cons),
        ),

        const SizedBox(height: 14),

        // Bouton fermer
        _BoutonPrimaire(
          label: 'Continuer',
          onTap: onFermer,
        ),
      ],
    );
  }

  List<Widget> _construireChips(ConsequencesEvenement cons) {
    final chips = <Widget>[];

    if ((cons.orGagne ?? 0) > 0)
      chips.add(_ChipConsequence(
          emoji: '🪙', label: '+${cons.orGagne} or',
          couleur: _or));
    if ((cons.orPerdu ?? 0) > 0)
      chips.add(_ChipConsequence(
          emoji: '🪙', label: '-${cons.orPerdu} or',
          couleur: _rouge));
    if ((cons.renommeeBonus ?? 0) > 0)
      chips.add(_ChipConsequence(
          emoji: '⭐', label: '+${cons.renommeeBonus} renommée',
          couleur: const Color(0xFF8899FF)));
    if ((cons.renommeePerte ?? 0) > 0)
      chips.add(_ChipConsequence(
          emoji: '⭐', label: '-${cons.renommeePerte} renommée',
          couleur: _rouge));
    if (cons.substratBonus != null)
      for (final e in cons.substratBonus!.entries)
        chips.add(_ChipConsequence(
            emoji: '📈', label: '+${e.value} ${e.key}',
            couleur: const Color(0xFF4169E1)));
    if (cons.statBonus != null)
      for (final e in cons.statBonus!.entries)
        chips.add(_ChipConsequence(
            emoji: '💪', label: '+${e.value} ${e.key}',
            couleur: const Color(0xFFC9A84C)));
    if (cons.objetGagne != null)
      for (final e in cons.objetGagne!.entries)
        chips.add(_ChipConsequence(
            emoji: '📦', label: '${e.key} ×${e.value}',
            couleur: _texte));
    if (cons.mercenaireGagne)
      chips.add(_ChipConsequence(
          emoji: '👤', label: 'Nouveau mercenaire',
          couleur: const Color(0xFF27AE60)));
    if (cons.classeDebloquee != null)
      chips.add(_ChipConsequence(
          emoji: '🌟', label: 'Classe débloquée',
          couleur: _or));
    if (cons.classeIndice != null)
      chips.add(_ChipConsequence(
          emoji: '🔍', label: 'Indice de classe',
          couleur: _orDim));
    if (cons.batimentDecouvert != null)
      chips.add(_ChipConsequence(
          emoji: '🏚️', label: 'Bâtiment découvert',
          couleur: const Color(0xFF27AE60)));
    if (cons.batimentEndommage)
      chips.add(_ChipConsequence(
          emoji: '⚠️', label: 'Bâtiment endommagé',
          couleur: const Color(0xFFE67E22)));
    if (cons.batimentDetruit)
      chips.add(_ChipConsequence(
          emoji: '💥', label: 'Bâtiment détruit',
          couleur: _rouge));
    if (cons.blessure != null || cons.blessureAleatoire != null)
      chips.add(_ChipConsequence(
          emoji: '🩸', label: 'Blessure',
          couleur: _rouge));
    if (cons.evenementDebloque != null)
      chips.add(_ChipConsequence(
          emoji: '📖', label: 'Suite débloquée',
          couleur: _or));

    return chips;
  }
}

class _ChipConsequence extends StatelessWidget {
  final String emoji, label;
  final Color couleur;
  const _ChipConsequence({
    required this.emoji, required this.label,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: couleur.withOpacity(0.08),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(
          color: couleur.withOpacity(0.25),
          width: 0.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji,
            style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: couleur, fontSize: 10,
                fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
