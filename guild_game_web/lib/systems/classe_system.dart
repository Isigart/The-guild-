// lib/systems/classe_system.dart
// ClasseSystem optimisé — index inversé + vérification ciblée

import '../models/enums.dart';
import '../models/mercenaire.dart';
import '../models/classe.dart';
import '../models/sort.dart';
import '../models/etat_jeu.dart';
import '../data/classe_loader.dart';

class ClasseSystem {
  List<Classe>? _classes;

  // Index inversés — construits une seule fois au chargement
  final Map<StatPrincipale, List<Classe>> _indexParStat = {};
  final Map<Substat, List<Classe>> _indexParSubstat = {};
  final List<Classe> _classesConditionSpeciale = [];
  final Map<String, Classe> _indexParId = {};

  Future<void> initialiser() async {
    _classes = await ClasseLoader.chargerToutes();
    _construireIndex();
  }

  void _construireIndex() {
    if (_classes == null) return;
    _indexParStat.clear();
    _indexParSubstat.clear();
    _classesConditionSpeciale.clear();
    _indexParId.clear();

    for (final classe in _classes!) {
      _indexParId[classe.id] = classe;

      for (final stat in classe.reqStats.keys) {
        _indexParStat.putIfAbsent(stat, () => []).add(classe);
      }
      for (final sub in classe.reqSubstats.keys) {
        _indexParSubstat.putIfAbsent(sub, () => []).add(classe);
      }
      if (classe.reqStats.isEmpty && classe.reqSubstats.isEmpty && classe.conditionSpeciale != null) {
        _classesConditionSpeciale.add(classe);
      }
    }
  }

  // Après gain de stat principale (appelé depuis distribuerStat)
  Classe? verifierApresStatChange(Mercenaire merc, StatPrincipale stat, EtatJeu etat) =>
      _premiereEligible(merc, _indexParStat[stat] ?? [], etat);

  // Après gain de substat (appelé depuis appliquerSubstats)
  Classe? verifierApresSubstatChange(Mercenaire merc, Substat sub, EtatJeu etat) =>
      _premiereEligible(merc, _indexParSubstat[sub] ?? [], etat);

  // Après gain de niveau (classes rares basées sur le niveau)
  Classe? verifierApresNiveau(Mercenaire merc, EtatJeu etat) {
    final classesNiveau = _classes?.where((c) =>
        c.conditionSpeciale != null &&
        c.conditionSpeciale!.description.toLowerCase().contains('niveau')).toList() ?? [];
    return _premiereEligible(merc, classesNiveau, etat);
  }

  // Conditions spéciales — début de journée uniquement
  Classe? verifierConditionsSpeciales(Mercenaire merc, EtatJeu etat) =>
      _premiereEligible(merc, _classesConditionSpeciale, etat);

  Classe? _premiereEligible(Mercenaire merc, List<Classe> candidates, EtatJeu etat) {
    if (candidates.isEmpty) return null;
    final tries = List<Classe>.from(candidates)
      ..sort((a, b) => b.tier.index.compareTo(a.tier.index));
    for (final c in tries) {
      if (_estEligible(merc, c, etat)) return c;
    }
    return null;
  }

  bool _estEligible(Mercenaire merc, Classe classe, EtatJeu etat) {
    if (_dejaObtenue(merc, classe)) return false;
    if (!_tierAcceptable(classe, merc.classeActuelle)) return false;
    if (!_batimentDisponible(classe, etat)) return false;
    for (final e in classe.reqStats.entries) {
      if ((merc.stats[e.key] ?? 1) < e.value) return false;
    }
    for (final e in classe.reqSubstats.entries) {
      if (merc.getSubstat(e.key) < e.value) return false;
    }
    if (classe.conditionSpeciale != null) {
      if (!classe.conditionSpeciale!.verifier(merc, etat)) return false;
    }
    return true;
  }

  bool _dejaObtenue(Mercenaire merc, Classe c) =>
      merc.classeActuelle.id == c.id ||
      merc.historiqueClasses.any((h) => h.id == c.id);

  bool _tierAcceptable(Classe candidate, Classe actuelle) =>
      candidate.tier.index >= actuelle.tier.index;

  bool _batimentDisponible(Classe classe, EtatJeu etat) {
    if (classe.tier != ClasseTier.secret) return true;
    if (classe.affinites.isEmpty) return true;
    return classe.affinites.any((t) =>
        etat.batiments.any((b) => b.type == t && b.estDecouvert));
  }

  Classe? getById(String id) => _indexParId[id];

  Classe classeBase() => _indexParId['mercenaire'] ?? _classeBaseDefault();

  List<ClasseProgress> classesEnApproche(Mercenaire merc, EtatJeu etat) {
    if (_classes == null) return [];
    return _classes!
        .where((c) =>
            !_dejaObtenue(merc, c) &&
            _tierAcceptable(c, merc.classeActuelle) &&
            _batimentDisponible(c, etat) &&
            c.tier != ClasseTier.rare &&
            c.tier != ClasseTier.secret)
        .map((c) => _calculerProgress(merc, c))
        .where((p) => p.pourcentage >= 0.5)
        .toList()
      ..sort((a, b) => b.pourcentage.compareTo(a.pourcentage));
  }

  ClasseProgress _calculerProgress(Mercenaire merc, Classe classe) {
    int total = 0, atteints = 0;
    final manque = <String, int>{};
    for (final e in classe.reqStats.entries) {
      total += e.value;
      final actuel = (merc.stats[e.key] ?? 1).clamp(0, e.value);
      atteints += actuel;
      if (actuel < e.value) manque[e.key.shortLabel] = e.value - actuel;
    }
    for (final e in classe.reqSubstats.entries) {
      total += e.value;
      final actuel = merc.getSubstat(e.key).clamp(0, e.value);
      atteints += actuel;
      if (actuel < e.value) manque[e.key.label] = e.value - actuel;
    }
    return ClasseProgress(
      classe: classe,
      atteints: atteints,
      total: total,
      pourcentage: total > 0 ? atteints / total : 0.0,
      detailsManquants: manque,
    );
  }

  String genererNotification(Mercenaire merc, Classe nouvelleClasse) =>
      '${merc.nom} a changé. ${_texteTransition(nouvelleClasse)} '
      '${nouvelleClasse.description} '
      'Sort acquis : ${nouvelleClasse.sort.emoji} ${nouvelleClasse.sort.nom}.';

  String _texteTransition(Classe c) {
    if (c.tier == ClasseTier.rare)   return "Quelque chose d'extraordinaire s'est produit.";
    if (c.tier == ClasseTier.secret) return "Une porte s'est ouverte que peu franchissent.";
    switch (c.tier) {
      case ClasseTier.t1: return "Une première étape sur un long chemin.";
      case ClasseTier.t2: return "L'expérience forge quelque chose de solide.";
      case ClasseTier.t3: return "Les années de labeur portent leurs fruits.";
      case ClasseTier.t4: return "Une légende est née.";
      default: return '';
    }
  }

  Classe _classeBaseDefault() => Classe(
    id: 'mercenaire', nom: 'Mercenaire', emoji: '⚔️',
    tier: ClasseTier.base, type: ClasseType.combattant,
    description: 'Un mercenaire sans passé connu.',
    sort: Sort(
      id: 'sort_base', nom: 'Attaque', emoji: '⚔️',
      type: SortType.actif, cooldown: 0, description: 'Attaque basique.',
      effet: SortEffet(
        typeEffet: SortEffetType.degatsPhysiques,
        multiplicateur: 1.0, cible: SortCible.ennemicible,
      ),
    ),
  );
}

class ClasseProgress {
  final Classe classe;
  final int atteints;
  final int total;
  final double pourcentage;
  final Map<String, int> detailsManquants;
  const ClasseProgress({
    required this.classe, required this.atteints,
    required this.total, required this.pourcentage,
    required this.detailsManquants,
  });

  // ── Toutes les classes disponibles pour ce mercenaire ──
  // Retourne liste vide si aucune, [1] si auto, [2+] si choix
  List<Classe> classesDisponibles(Mercenaire merc, EtatJeu etat) {
    final tierCible = ClasseTier.values[
      (merc.classeActuelle.tier.index + 1)
          .clamp(0, ClasseTier.values.length - 1)
    ];

    return _classes.values.where((c) {
      // Même tier cible
      if (c.tier != tierCible) return false;
      // Vérifier stats
      for (final entry in c.reqStats.entries) {
        if ((merc.stats[entry.key] ?? 0) < entry.value) return false;
      }
      // Vérifier substats
      for (final entry in c.reqSubstats.entries) {
        if (merc.getSubstat(entry.key) < entry.value) return false;
      }
      // Vérifier condition spéciale
      if (c.conditionSpeciale != null) {
        if (!c.conditionSpeciale!.verifier(merc, etat)) return false;
      }
      return true;
    }).toList();
  }

  Map<String, Classe> get classes => _classes;

  Classe? getClasse(String id) => _classes[id];
}
