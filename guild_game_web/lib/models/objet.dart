// lib/models/objet.dart
// Modèle des objets du coffre de guilde

enum QualiteObjet { commun, rare, epique, legendaire }

enum TypeObjet { ressource, declencheur_evenement }

class Objet {
  final String id;
  final String nom;
  final String emoji;
  final TypeObjet type;
  final QualiteObjet qualite;
  final int valeurBase;
  final String description;

  // Pour les ressources — quels bâtiments elles améliorent/construisent
  final List<String> constructionCibles;   // IDs de bâtiments à construire
  final List<String> ameliorationCibles;   // IDs d'améliorations (ex: "forge_1_2")

  // Pour les déclencheurs — quel événement ils activent
  final String? evenementId;

  // Sources de drop
  final List<String> sources;

  const Objet({
    required this.id,
    required this.nom,
    required this.emoji,
    required this.type,
    required this.qualite,
    required this.valeurBase,
    required this.description,
    this.constructionCibles = const [],
    this.ameliorationCibles = const [],
    this.evenementId,
    this.sources = const [],
  });

  // Valeur de vente selon les passifs commerce civils
  int valeurVente(double multiplicateurCommerce) {
    return (valeurBase * (1.0 + multiplicateurCommerce)).round();
  }

  // Couleur selon qualité
  String get couleurHex {
    switch (qualite) {
      case QualiteObjet.commun:     return '#8B7355'; // brun
      case QualiteObjet.rare:       return '#4169E1'; // bleu
      case QualiteObjet.epique:     return '#8B008B'; // violet
      case QualiteObjet.legendaire: return '#FFD700'; // or
    }
  }

  String get emojiBordure {
    switch (qualite) {
      case QualiteObjet.commun:     return '🟤';
      case QualiteObjet.rare:       return '🔵';
      case QualiteObjet.epique:     return '🟣';
      case QualiteObjet.legendaire: return '⭐';
    }
  }

  factory Objet.fromJson(Map<String, dynamic> j) {
    final typeStr = j['type'] as String? ?? 'ressource';
    final qualiteStr = j['qualite'] as String? ?? 'commun';
    final utilisations = j['utilisations'] as Map<String, dynamic>? ?? {};

    return Objet(
      id:          j['id'] as String,
      nom:         j['nom'] as String,
      emoji:       j['emoji'] as String,
      type:        typeStr == 'declencheur_evenement'
                     ? TypeObjet.declencheur_evenement
                     : TypeObjet.ressource,
      qualite:     QualiteObjet.values.firstWhere(
                     (q) => q.name == qualiteStr,
                     orElse: () => QualiteObjet.commun,
                   ),
      valeurBase:  (j['valeurBase'] as num?)?.toInt() ?? 0,
      description: j['description'] as String? ?? '',
      constructionCibles: List<String>.from(utilisations['construction'] ?? []),
      ameliorationCibles: List<String>.from(utilisations['amelioration'] ?? []),
      evenementId: j['declencheEvenement'] as String?,
      sources:     List<String>.from(j['sources'] ?? []),
    );
  }
}

// ── Entrée du coffre de guilde ──
class EntreeCoffre {
  final Objet objet;
  int quantite;

  EntreeCoffre({required this.objet, this.quantite = 1});
}

// ── Coffre de guilde ──
class CoffreGuilde {
  final List<EntreeCoffre> entrees;

  CoffreGuilde({List<EntreeCoffre>? entrees})
      : entrees = entrees ?? [];

  // Ajouter des objets
  void ajouter(Objet objet, int quantite) {
    final existant = entrees.firstWhere(
      (e) => e.objet.id == objet.id,
      orElse: () {
        final nouv = EntreeCoffre(objet: objet);
        entrees.add(nouv);
        return nouv;
      },
    );
    existant.quantite += quantite;
  }

  // Retirer des objets — retourne false si pas assez
  bool retirer(String objetId, int quantite) {
    final idx = entrees.indexWhere((e) => e.objet.id == objetId);
    if (idx < 0) return false;
    if (entrees[idx].quantite < quantite) return false;
    entrees[idx].quantite -= quantite;
    if (entrees[idx].quantite <= 0) entrees.removeAt(idx);
    return true;
  }

  // Vérifier si on a assez d'un objet
  bool aAssez(String objetId, int quantite) {
    final e = entrees.firstWhere(
      (e) => e.objet.id == objetId,
      orElse: () => EntreeCoffre(objet: _objetVide, quantite: 0),
    );
    return e.quantite >= quantite;
  }

  // Vérifier si on a tous les objets requis pour une recette
  bool peutCrafter(Map<String, int> recette) {
    return recette.entries.every((e) => aAssez(e.key, e.value));
  }

  int quantiteDe(String objetId) {
    final e = entrees.firstWhere(
      (e) => e.objet.id == objetId,
      orElse: () => EntreeCoffre(objet: _objetVide, quantite: 0),
    );
    return e.quantite;
  }

  int get totalObjets => entrees.fold(0, (sum, e) => sum + e.quantite);

  // Sérialisation
  Map<String, dynamic> toJson() => {
    'entrees': entrees.map((e) => {
      'objetId': e.objet.id,
      'quantite': e.quantite,
    }).toList(),
  };

  static final _objetVide = Objet(
    id: '_vide', nom: '', emoji: '', type: TypeObjet.ressource,
    qualite: QualiteObjet.commun, valeurBase: 0, description: '',
  );
}
