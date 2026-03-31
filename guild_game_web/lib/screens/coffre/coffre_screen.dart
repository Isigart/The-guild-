// lib/screens/coffre/coffre_screen.dart
// Coffre de guilde — inventaire, vente, déclencheurs d'événements

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/objet.dart';
import '../../models/enums.dart';
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

// Couleur par qualité
Color _couleurQualite(QualiteObjet q) {
  switch (q) {
    case QualiteObjet.commun:     return const Color(0xFF8B7355);
    case QualiteObjet.rare:       return const Color(0xFF4169E1);
    case QualiteObjet.epique:     return const Color(0xFF8B008B);
    case QualiteObjet.legendaire: return _or;
  }
}

String _labelQualite(QualiteObjet q) {
  switch (q) {
    case QualiteObjet.commun:     return 'Commun';
    case QualiteObjet.rare:       return 'Rare';
    case QualiteObjet.epique:     return 'Épique';
    case QualiteObjet.legendaire: return 'Légendaire';
  }
}

// ══════════════════════════════════════════════════════
// ÉCRAN COFFRE
// ══════════════════════════════════════════════════════

class CoffreScreen extends ConsumerStatefulWidget {
  final void Function(String evenementId)? onDetonateur;
  const CoffreScreen({super.key, this.onDetonateur});

  @override
  ConsumerState<CoffreScreen> createState() => _CoffreScreenState();
}

class _CoffreScreenState extends ConsumerState<CoffreScreen> {
  // Filtre actif
  QualiteObjet? _filtreQualite;
  TypeObjet?    _filtreType;
  String        _recherche = '';

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(gameProvider);
    if (etat == null) return const SizedBox.shrink();

    final coffre  = etat.coffreGuilde;
    final entrees = _filtrerEntrees(coffre.entrees);
    final or      = etat.or;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // Header
          _CoffreHeader(
            total: coffre.totalObjets,
            or: or,
          ),

          // Filtres
          _Filtres(
            qualite:   _filtreQualite,
            type:      _filtreType,
            recherche: _recherche,
            onQualite: (q) => setState(() => _filtreQualite = q),
            onType:    (t) => setState(() => _filtreType = t),
            onRecherche: (s) => setState(() => _recherche = s),
          ),

          // Liste objets
          Expanded(
            child: entrees.isEmpty
                ? _MessageVide()
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: entrees.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 6),
                    itemBuilder: (_, i) => _LigneObjet(
                      entree: entrees[i],
                      or: or,
                      onVendre: (qte) =>
                          _vendre(entrees[i].objet.id, qte),
                      onUtiliser: entrees[i].objet.type ==
                              TypeObjet.declencheur_evenement
                          ? () => _utiliser(entrees[i].objet.id)
                          : null,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<EntreeCoffre> _filtrerEntrees(List<EntreeCoffre> entrees) {
    return entrees.where((e) {
      if (_filtreQualite != null &&
          e.objet.qualite != _filtreQualite) return false;
      if (_filtreType != null &&
          e.objet.type != _filtreType) return false;
      if (_recherche.isNotEmpty &&
          !e.objet.nom.toLowerCase()
              .contains(_recherche.toLowerCase())) return false;
      return true;
    }).toList()
      ..sort((a, b) {
        // Tri : légendaire → épique → rare → commun
        final qComp = b.objet.qualite.index
            .compareTo(a.objet.qualite.index);
        if (qComp != 0) return qComp;
        return a.objet.nom.compareTo(b.objet.nom);
      });
  }

  void _vendre(String objetId, int quantite) {
    ref.read(gameProvider.notifier).vendreObjet(objetId, quantite);
    setState(() {});
  }

  void _utiliser(String objetId) {
    final evId = ref.read(gameProvider.notifier)
        .utiliserDetonateur(objetId);
    if (evId != null && widget.onDetonateur != null) {
      widget.onDetonateur!(evId);
    }
    setState(() {});
  }
}

// ══════════════════════════════════════════════════════
// HEADER
// ══════════════════════════════════════════════════════

class _CoffreHeader extends StatelessWidget {
  final int total, or;
  const _CoffreHeader({required this.total, required this.or});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
        16, MediaQuery.of(context).padding.top + 8, 16, 10),
    decoration: const BoxDecoration(
      color: Color(0xFF060402),
      border: Border(bottom: BorderSide(color: _border)),
    ),
    child: Row(
      children: [
        const Text('📦', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('COFFRE DE GUILDE',
                  style: TextStyle(
                      color: _or, fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5)),
              Text('$total objet${total > 1 ? 's' : ''}',
                  style: const TextStyle(
                      color: _dim, fontSize: 10,
                      fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _or.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: _orDim.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Text('🪙',
                  style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text('$or',
                  style: const TextStyle(
                      color: _or, fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════
// FILTRES
// ══════════════════════════════════════════════════════

class _Filtres extends StatelessWidget {
  final QualiteObjet? qualite;
  final TypeObjet? type;
  final String recherche;
  final void Function(QualiteObjet?) onQualite;
  final void Function(TypeObjet?) onType;
  final void Function(String) onRecherche;

  const _Filtres({
    required this.qualite, required this.type,
    required this.recherche,
    required this.onQualite, required this.onType,
    required this.onRecherche,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: _border)),
    ),
    child: Column(
      children: [
        // Filtres qualité
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _ChipFiltre(
                label: 'Tous',
                actif: qualite == null && type == null,
                onTap: () {
                  onQualite(null);
                  onType(null);
                },
              ),
              const SizedBox(width: 6),
              _ChipFiltre(
                label: '🔵 Rares+',
                actif: qualite == QualiteObjet.rare,
                couleur: const Color(0xFF4169E1),
                onTap: () => onQualite(
                    qualite == QualiteObjet.rare
                        ? null
                        : QualiteObjet.rare),
              ),
              const SizedBox(width: 6),
              _ChipFiltre(
                label: '🗝️ Déclencheurs',
                actif: type == TypeObjet.declencheur_evenement,
                couleur: _or,
                onTap: () => onType(
                    type == TypeObjet.declencheur_evenement
                        ? null
                        : TypeObjet.declencheur_evenement),
              ),
              const SizedBox(width: 6),
              _ChipFiltre(
                label: '🔧 Ressources',
                actif: type == TypeObjet.ressource,
                couleur: _dim,
                onTap: () => onType(
                    type == TypeObjet.ressource
                        ? null
                        : TypeObjet.ressource),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ChipFiltre extends StatelessWidget {
  final String label;
  final bool actif;
  final Color couleur;
  final VoidCallback onTap;
  const _ChipFiltre({
    required this.label, required this.actif,
    required this.onTap,
    this.couleur = _dim,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: actif
            ? couleur.withOpacity(0.12)
            : _bg3,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: actif
              ? couleur.withOpacity(0.5)
              : _border,
        ),
      ),
      child: Text(label,
          style: TextStyle(
              color: actif ? couleur : _dim,
              fontSize: 10,
              fontWeight: FontWeight.w600)),
    ),
  );
}

// ══════════════════════════════════════════════════════
// LIGNE OBJET
// ══════════════════════════════════════════════════════

class _LigneObjet extends StatelessWidget {
  final EntreeCoffre entree;
  final int or;
  final void Function(int) onVendre;
  final VoidCallback? onUtiliser;
  const _LigneObjet({
    required this.entree, required this.or,
    required this.onVendre, this.onUtiliser,
  });

  Objet get obj => entree.objet;

  @override
  Widget build(BuildContext context) {
    final couleur = _couleurQualite(obj.qualite);
    final estDeclencheur =
        obj.type == TypeObjet.declencheur_evenement;

    return Container(
      decoration: BoxDecoration(
        color: _bg3,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: couleur.withOpacity(0.2),
          width: estDeclencheur ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _afficherDetail(context),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Emoji
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: couleur.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: couleur.withOpacity(0.2),
                        width: 0.5),
                  ),
                  child: Center(
                    child: Text(obj.emoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(obj.nom,
                                style: TextStyle(
                                    color: couleur,
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w700)),
                          ),
                          // Quantité
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  couleur.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(4),
                            ),
                            child: Text(
                                '×${entree.quantite}',
                                style: TextStyle(
                                    color: couleur,
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight.w800)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _labelQualite(obj.qualite),
                            style: TextStyle(
                                color: couleur
                                    .withOpacity(0.6),
                                fontSize: 9,
                                fontWeight:
                                    FontWeight.w600),
                          ),
                          if (estDeclencheur) ...[
                            const SizedBox(width: 6),
                            Text('🗝️ Déclencheur',
                                style: TextStyle(
                                    color: _or
                                        .withOpacity(0.6),
                                    fontSize: 9)),
                          ],
                          const Spacer(),
                          Text(
                            '🪙 ${obj.valeurBase}',
                            style: const TextStyle(
                                color: _orDim,
                                fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _afficherDetail(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailObjet(
        entree: entree,
        or: or,
        onVendre: onVendre,
        onUtiliser: onUtiliser,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// DETAIL OBJET (bottom sheet)
// ══════════════════════════════════════════════════════

class _DetailObjet extends StatefulWidget {
  final EntreeCoffre entree;
  final int or;
  final void Function(int) onVendre;
  final VoidCallback? onUtiliser;
  const _DetailObjet({
    required this.entree, required this.or,
    required this.onVendre, this.onUtiliser,
  });

  @override
  State<_DetailObjet> createState() => _DetailObjetState();
}

class _DetailObjetState extends State<_DetailObjet> {
  int _qteVente = 1;

  Objet get obj => widget.entree.objet;

  @override
  Widget build(BuildContext context) {
    final couleur = _couleurQualite(obj.qualite);
    final estDeclencheur =
        obj.type == TypeObjet.declencheur_evenement;
    final prixTotal = obj.valeurBase * _qteVente;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0C0A06),
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: _border),
          left: BorderSide(color: _border),
          right: BorderSide(color: _border),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poignée
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(
                  vertical: 10),
              width: 36, height: 3,
              decoration: BoxDecoration(
                  color: _border,
                  borderRadius:
                      BorderRadius.circular(2)),
            ),
          ),

          // En-tête
          Row(
            children: [
              Text(obj.emoji,
                  style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(obj.nom,
                        style: TextStyle(
                            color: couleur,
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w700)),
                    Text(_labelQualite(obj.qualite),
                        style: TextStyle(
                            color: couleur
                                .withOpacity(0.6),
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4),
                decoration: BoxDecoration(
                  color: couleur.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                    '×${widget.entree.quantite}',
                    style: TextStyle(
                        color: couleur,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w800)),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _bg3,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _border),
            ),
            child: Text(obj.description,
                style: const TextStyle(
                    color: _texte,
                    fontSize: 11,
                    height: 1.5,
                    fontStyle: FontStyle.italic)),
          ),

          const SizedBox(height: 14),

          // Utilisations (ressource)
          if (obj.type == TypeObjet.ressource &&
              obj.ameliorationCibles.isNotEmpty) ...[
            _SectionInfo(
              label: 'AMÉLIORE',
              contenu: obj.ameliorationCibles
                  .take(4)
                  .join(', '),
            ),
            const SizedBox(height: 10),
          ],

          // Déclencheur
          if (estDeclencheur) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _or.withOpacity(0.05),
                borderRadius:
                    BorderRadius.circular(6),
                border: Border.all(
                    color: _orDim.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Text('🗝️',
                      style:
                          TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Utiliser cet objet déclenchera un événement unique.',
                      style: TextStyle(
                          color: _orDim,
                          fontSize: 10,
                          fontStyle:
                              FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Bouton utiliser
            _BoutonAction(
              label: 'Utiliser',
              sous: 'Déclenche un événement',
              couleur: _or,
              onTap: () {
                Navigator.pop(context);
                widget.onUtiliser?.call();
              },
            ),
            const SizedBox(height: 8),
          ],

          // Section vente
          if (!estDeclencheur || widget.entree.quantite > 1) ...[
            const Divider(color: _border),
            const SizedBox(height: 8),

            Row(
              children: [
                const Text('VENTE',
                    style: TextStyle(
                        color: _dim,
                        fontSize: 9,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('🪙 $prixTotal or',
                    style: const TextStyle(
                        color: _or,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),

            // Sélecteur quantité
            if (widget.entree.quantite > 1)
              _SelecteurQuantite(
                min: 1,
                max: widget.entree.quantite,
                valeur: _qteVente,
                onChange: (v) =>
                    setState(() => _qteVente = v),
              ),

            const SizedBox(height: 10),

            _BoutonAction(
              label: 'Vendre ×$_qteVente',
              sous: '🪙 $prixTotal or',
              couleur: _dim,
              onTap: () {
                Navigator.pop(context);
                widget.onVendre(_qteVente);
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// COMPOSANTS
// ══════════════════════════════════════════════════════

class _SectionInfo extends StatelessWidget {
  final String label, contenu;
  const _SectionInfo({required this.label, required this.contenu});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: const TextStyle(
              color: _dim, fontSize: 9,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(contenu,
            style: const TextStyle(
                color: _texte, fontSize: 10)),
      ),
    ],
  );
}

class _SelecteurQuantite extends StatelessWidget {
  final int min, max, valeur;
  final void Function(int) onChange;
  const _SelecteurQuantite({
    required this.min, required this.max,
    required this.valeur, required this.onChange,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _BtnQte(label: '-',
          actif: valeur > min,
          onTap: () => onChange((valeur - 1).clamp(min, max))),
      Container(
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _bg3,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _border),
        ),
        child: Center(
          child: Text('$valeur',
              style: const TextStyle(
                  color: _texte, fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ),
      ),
      _BtnQte(label: '+',
          actif: valeur < max,
          onTap: () => onChange((valeur + 1).clamp(min, max))),
      const SizedBox(width: 12),
      GestureDetector(
        onTap: () => onChange(max),
        child: Text('MAX',
            style: TextStyle(
                color: _orDim.withOpacity(0.6),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
      ),
    ],
  );
}

class _BtnQte extends StatelessWidget {
  final String label;
  final bool actif;
  final VoidCallback onTap;
  const _BtnQte({required this.label, required this.actif,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: actif ? onTap : null,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: actif ? _bg3 : _bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: actif ? _border : _border.withOpacity(0.4)),
      ),
      child: Center(
        child: Text(label,
            style: TextStyle(
                color: actif ? _texte : _dim,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
      ),
    ),
  );
}

class _BoutonAction extends StatelessWidget {
  final String label, sous;
  final Color couleur;
  final VoidCallback? onTap;
  const _BoutonAction({
    required this.label, required this.sous,
    required this.couleur, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: couleur.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: couleur, fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
          Text(sous,
              style: TextStyle(
                  color: couleur.withOpacity(0.5),
                  fontSize: 9)),
        ],
      ),
    ),
  );
}

class _MessageVide extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('📦', style: TextStyle(fontSize: 40)),
        SizedBox(height: 12),
        Text('Le coffre est vide.',
            style: TextStyle(
                color: _dim, fontSize: 13,
                fontStyle: FontStyle.italic)),
        SizedBox(height: 6),
        Text('Explorez les zones pour trouver des ressources.',
            style: TextStyle(
                color: _dim, fontSize: 10)),
      ],
    ),
  );
}
