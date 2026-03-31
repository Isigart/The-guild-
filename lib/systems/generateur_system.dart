// lib/systems/generateur_system.dart
// Génère mercenaires, ennemis et zones — branché aux vrais modèles

import 'dart:math';
import '../models/enums.dart';
import '../models/mercenaire.dart';
import '../models/classe.dart';
import '../models/models.dart';

class GenerateurSystem {
  final Random _rng = Random();

  // ═══════════════════════════════════════════════════════
  // NOMS
  // ═══════════════════════════════════════════════════════

  static const _prenoms = [
    'Aldric','Bryn','Caelum','Dara','Edwyn','Fenn','Gorin','Hilde',
    'Ivar','Jora','Kael','Lyra','Moric','Nessa','Orin','Petra',
    'Quinn','Ragna','Sven','Tara','Ulric','Vira','Wulf','Yorn',
  ];

  static const _surnoms = [
    'le Brisé','aux Cicatrices','sans Foyer','l\'Errant','du Néant',
    'Maudit','l\'Oublié','aux Yeux Creux','Froid-Fer','le Borgne',
    'de Nulle Part','la Lame','aux Mains Vides','Fer-Froid','sans Maître',
    'l\'Affamé','au Cœur Vide','des Ruines','le Taciturne','l\'Exilé',
  ];

  String genererNom() {
    final prenom = _prenoms[_rng.nextInt(_prenoms.length)];
    final surnom = _surnoms[_rng.nextInt(_surnoms.length)];
    return '$prenom $surnom';
  }

  // ═══════════════════════════════════════════════════════
  // MERCENAIRES
  // ═══════════════════════════════════════════════════════

  Mercenaire genererMercenaire(String id, Classe classeBase) {
    return Mercenaire(
      id: id,
      nom: genererNom(),
      classeActuelle: classeBase,
      // Toutes les stats à 1 pour éviter les bugs
      stats: {for (final s in StatPrincipale.values) s: 1},
    );
  }

  // Génère une recrue selon la Renommée de la guilde
  Mercenaire genererRecrue(String id, Classe classeBase, RenommeeNiveau renommee) {
    final merc = genererMercenaire(id, classeBase);

    // Bonus de stats selon la renommée
    final bonusStats = _bonusRecrueParRenommee(renommee);
    for (int i = 0; i < bonusStats; i++) {
      final stat = StatPrincipale.values[_rng.nextInt(StatPrincipale.values.length)];
      merc.stats[stat] = (merc.stats[stat] ?? 1) + 1;
    }

    // Bonus de substats selon la renommée
    final bonusSubs = _bonusSubstatParRenommee(renommee);
    for (int i = 0; i < bonusSubs; i++) {
      final sub = Substat.values[_rng.nextInt(Substat.values.length)];
      merc.ajouterSubstat(sub);
    }

    return merc;
  }

  int _bonusRecrueParRenommee(RenommeeNiveau r) {
    switch (r) {
      case RenommeeNiveau.ruines:    return 0;
      case RenommeeNiveau.inconnue:  return 0;
      case RenommeeNiveau.locale:    return 2;
      case RenommeeNiveau.regionale: return 5;
      case RenommeeNiveau.reconnue:  return 10;
      case RenommeeNiveau.sommet:    return 20;
    }
  }

  int _bonusSubstatParRenommee(RenommeeNiveau r) {
    switch (r) {
      case RenommeeNiveau.ruines:    return 0;
      case RenommeeNiveau.inconnue:  return 0;
      case RenommeeNiveau.locale:    return 3;
      case RenommeeNiveau.regionale: return 8;
      case RenommeeNiveau.reconnue:  return 15;
      case RenommeeNiveau.sommet:    return 30;
    }
  }

  // ═══════════════════════════════════════════════════════
  // ENNEMIS — templates avec résistances innées
  // ═══════════════════════════════════════════════════════

  static const Map<TypeEnnemi, _TemplateEnnemi> _templates = {
    TypeEnnemi.gobelin: _TemplateEnnemi(
      nom: 'Gobelin', emoji: '👺',
      hpBase: 20, atkBase: 5,
      resistances: {'magique': 0.5},      // résistant magie
      faiblesses: {'physique': 1.5},      // faible physique
    ),
    TypeEnnemi.orc: _TemplateEnnemi(
      nom: 'Orc', emoji: '💪',
      hpBase: 45, atkBase: 9,
      resistances: {'physique': 0.8},
      faiblesses: {'magique': 1.3},
    ),
    TypeEnnemi.squelette: _TemplateEnnemi(
      nom: 'Squelette', emoji: '💀',
      hpBase: 25, atkBase: 7,
      resistances: {'poison': 0.0, 'tranchant': 0.5}, // immunisé poison
      faiblesses: {'contondant': 1.8},
    ),
    TypeEnnemi.troll: _TemplateEnnemi(
      nom: 'Troll', emoji: '🧌',
      hpBase: 80, atkBase: 12,
      resistances: {'physique': 0.6},     // très résistant physique
      faiblesses: {'feu': 1.8, 'magique': 1.4},
    ),
    TypeEnnemi.sorcier: _TemplateEnnemi(
      nom: 'Sorcier', emoji: '🧙',
      hpBase: 30, atkBase: 14,
      resistances: {'magique': 0.3},      // très résistant magie
      faiblesses: {'physique': 1.6},
    ),
    TypeEnnemi.dragon: _TemplateEnnemi(
      nom: 'Dragon', emoji: '🐉',
      hpBase: 150, atkBase: 20,
      resistances: {'feu': 0.0, 'physique': 0.7},
      faiblesses: {'glace': 2.0, 'magique': 1.2},
    ),
    TypeEnnemi.araignee: _TemplateEnnemi(
      nom: 'Araignée Géante', emoji: '🕷️',
      hpBase: 35, atkBase: 8,
      resistances: {'poison': 0.0, 'toile': 0.0},
      faiblesses: {'feu': 1.5, 'contondant': 1.3},
    ),
    TypeEnnemi.vampire: _TemplateEnnemi(
      nom: 'Vampire', emoji: '🧛',
      hpBase: 55, atkBase: 13,
      resistances: {'physique': 0.6, 'poison': 0.0},
      faiblesses: {'lumiere': 2.5, 'feu': 1.8},
    ),
    TypeEnnemi.elementaire: _TemplateEnnemi(
      nom: 'Élémentaire', emoji: '🌋',
      hpBase: 40, atkBase: 11,
      resistances: {},  // résistances dynamiques selon type
      faiblesses: {},
    ),
    TypeEnnemi.bandit: _TemplateEnnemi(
      nom: 'Bandit', emoji: '🗡️',
      hpBase: 22, atkBase: 6,
      resistances: {},
      faiblesses: {'magique': 1.2},
    ),
    TypeEnnemi.boss: _TemplateEnnemi(
      nom: 'Boss', emoji: '☠️',
      hpBase: 200, atkBase: 25,
      resistances: {'physique': 0.7, 'magique': 0.7},
      faiblesses: {},
    ),
  };

  // Génère les ennemis pour une zone
  List<Ennemi> genererEnnemis(Zone zone, {bool estBoss = false}) {
    if (estBoss) return [_genererBoss(zone)];

    final count = _nombreEnnemis(zone.numero);
    final types = zone.typesEnnemis;

    return List.generate(count, (i) {
      final type = types[_rng.nextInt(types.length)];
      return _genererEnnemi(type, zone.numero, i.toString());
    });
  }

  Ennemi _genererEnnemi(TypeEnnemi type, int numeroZone, String suffix) {
    final template = _templates[type] ?? _templates[TypeEnnemi.bandit]!;
    final scale = _calculerScale(numeroZone);
    final variance = 0.85 + (_rng.nextDouble() * 0.30); // ±15% aléatoire

    return Ennemi(
      id: '${type.name}_${numeroZone}_$suffix',
      nom: template.nom,
      emoji: template.emoji,
      type: type,
      hpMax: (template.hpBase * scale * variance).round(),
      atk: (template.atkBase * scale * variance).round(),
      resistances: Map.from(template.resistances),
    );
  }

  Ennemi _genererBoss(Zone zone) {
    final multiplicateur = _multiplicateurBoss(zone.numero);
    final scale = _calculerScale(zone.numero);

    // Le boss est toujours le type le plus fort de la zone
    final typeBoss = zone.typesEnnemis.last;
    final template = _templates[typeBoss] ?? _templates[TypeEnnemi.boss]!;

    return Ennemi(
      id: 'boss_zone_${zone.numero}',
      nom: '${template.nom} Légendaire',
      emoji: '☠️',
      type: TypeEnnemi.boss,
      hpMax: (template.hpBase * scale * multiplicateur).round(),
      atk: (template.atkBase * scale * multiplicateur * 0.8).round(),
      estBoss: true,
      resistances: {
        ...template.resistances,
        'physique': (template.resistances['physique'] ?? 1.0) * 0.8,
        'magique': (template.resistances['magique'] ?? 1.0) * 0.8,
      },
    );
  }

  double _calculerScale(int numeroZone) =>
      1.0 + (numeroZone - 1) * 0.20;

  double _multiplicateurBoss(int numeroZone) {
    if (numeroZone <= 10) return 5.0;
    if (numeroZone <= 25) return 7.0;
    if (numeroZone <= 50) return 10.0;
    return 15.0;
  }

  int _nombreEnnemis(int numeroZone) =>
      (2 + (numeroZone * 0.4)).round().clamp(2, 8);

  // ═══════════════════════════════════════════════════════
  // ZONES — générées à la demande (infinie)
  // ═══════════════════════════════════════════════════════

  List<Zone> genererZonesInitiales() {
    return [
      Zone(
        numero: 1,
        nomCache: 'Chemin des Manants',
        description: 'Un chemin poussiéreux infesté de gobelins affamés. La première zone, la plus simple.',
        etat: ZoneEtat.mystere,
        niveauMin: 1, niveauMax: 5,
        typesEnnemis: [TypeEnnemi.gobelin, TypeEnnemi.bandit],
        orBase: 15, orBonus: 5,
        aBoss: true, nomBoss: 'Roi Gobelin',
      ),
      Zone(
        numero: 2,
        nomCache: 'Forêt des Ombres',
        description: 'Une forêt dense où rôdent des créatures plus dangereuses.',
        etat: ZoneEtat.inconnue,
        niveauMin: 5, niveauMax: 15,
        typesEnnemis: [TypeEnnemi.gobelin, TypeEnnemi.orc],
        orBase: 30, orBonus: 15,
        aBoss: true, nomBoss: 'Seigneur Orc',
      ),
      Zone(
        numero: 3,
        nomCache: 'Marais Maudit',
        description: 'Les morts marchent ici. Votre acier ne les arrêtera pas.',
        etat: ZoneEtat.inconnue,
        niveauMin: 15, niveauMax: 30,
        typesEnnemis: [TypeEnnemi.squelette, TypeEnnemi.sorcier],
        orBase: 60, orBonus: 30,
        aBoss: true, nomBoss: 'Archilliche',
      ),
      Zone(
        numero: 4,
        nomCache: 'Mines Abandonnées',
        description: 'Des tunnels obscurs peuplés de créatures qui n\'ont jamais vu la lumière.',
        etat: ZoneEtat.inconnue,
        niveauMin: 30, niveauMax: 50,
        typesEnnemis: [TypeEnnemi.troll, TypeEnnemi.araignee],
        orBase: 100, orBonus: 50,
        aBoss: true, nomBoss: 'Reine des Araignées',
      ),
      Zone(
        numero: 5,
        nomCache: 'Citadelle en Ruine',
        description: 'Ce château abritait autrefois une armée entière. Ses habitants actuels sont bien pires.',
        etat: ZoneEtat.inconnue,
        niveauMin: 50, niveauMax: 75,
        typesEnnemis: [TypeEnnemi.vampire, TypeEnnemi.squelette],
        orBase: 150, orBonus: 80,
        aBoss: true, nomBoss: 'Prince des Vampires',
      ),
    ];
  }

  // Génère une zone supplémentaire au-delà des zones initiales
  Zone genererZone(int numero) {
    final typesDisponibles = TypeEnnemi.values
        .where((t) => t != TypeEnnemi.boss)
        .toList();

    // Composition ennemis déterministe mais variée selon le numéro
    final seed = numero * 13;
    final type1 = typesDisponibles[seed % typesDisponibles.length];
    final type2 = typesDisponibles[(seed + 3) % typesDisponibles.length];

    return Zone(
      numero: numero,
      nomCache: _nomZoneAleatoire(numero),
      description: 'Une zone mystérieuse dont les dangers restent à découvrir.',
      etat: ZoneEtat.inconnue,
      niveauMin: numero * 5,
      niveauMax: (numero + 1) * 5 + 10,
      typesEnnemis: [type1, type2],
      orBase: 15 + (numero * 10),
      orBonus: 5 + (numero * 5),
      aBoss: numero % 5 == 0, // Boss tous les 5 niveaux
      nomBoss: numero % 5 == 0 ? 'Gardien de la Zone $numero' : null,
    );
  }

  String _nomZoneAleatoire(int numero) {
    final prefixes = ['Plaines','Forêt','Marais','Montagnes','Cavernes','Ruines','Temple','Désert'];
    final suffixes = ['Maudites','des Ombres','Interdites','Oubliées','Anciennes','du Néant'];
    final p = prefixes[numero % prefixes.length];
    final s = suffixes[(numero * 3) % suffixes.length];
    return '$p $s';
  }
}

// Template immuable pour les types d'ennemis
class _TemplateEnnemi {
  final String nom;
  final String emoji;
  final int hpBase;
  final int atkBase;
  final Map<String, double> resistances;
  final Map<String, double> faiblesses;

  const _TemplateEnnemi({
    required this.nom,
    required this.emoji,
    required this.hpBase,
    required this.atkBase,
    required this.resistances,
    required this.faiblesses,
  });
}
