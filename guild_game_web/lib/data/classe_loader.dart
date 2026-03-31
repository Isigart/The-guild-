// lib/data/classe_loader.dart
// Charge et parse les JSON de classes

import 'dart:convert';
import 'version_manager.dart';
import 'package:flutter/services.dart';
import '../models/classe.dart';
import '../models/sort.dart';
import '../models/enums.dart';

class ClasseLoader {
  static List<Classe>? _cache;

  static Future<List<Classe>> chargerToutes() async {
    if (_cache != null) return _cache!;

    final combattants = await _chargerFichier('assets/data/classes_combattants.json');
    final civiles = await _chargerFichier('assets/data/classes_civiles.json');
    final rares = await _chargerFichier('assets/data/classes_rares.json');

    final classes = <Classe>[
      ..._parseClasses(combattants['classes'] ?? []),
      ..._parseClasses(civiles['classes_civiles'] ?? []),
      ..._parseClasses(rares['classes_rares'] ?? []),
    ];

    _cache = classes;
    return classes;
  }

  static Future<Map<String, dynamic>> _chargerFichier(String path) async {
    try {
      final data = await rootBundle.loadString(path);
      final cleaned = VersionManager._supprimerCommentaires(data);
      final decoded = json.decode(cleaned) as Map<String, dynamic>;
      
      // Appliquer migration si nécessaire
      final version = DataVersion.parse(decoded['version'] ?? '1.0.0');
      final nomFichier = path.split('/').last.replaceAll('.json', '');
      return VersionManager.migrer(decoded, nomFichier, version);
    } catch (e) {
      print('Erreur chargement $path: $e');
      return {};
    }
  }

  static List<Classe> _parseClasses(List<dynamic> data) {
    return data.map((json) => _parseClasse(json as Map<String, dynamic>)).toList();
  }

  static Classe _parseClasse(Map<String, dynamic> json) {
    return Classe(
      id: json['id'] as String,
      nom: json['nom'] as String,
      emoji: json['emoji'] as String,
      tier: _parseTier(json['tier'] as String),
      type: _parseType(json['type'] as String),
      description: json['description'] as String,
      sort: _parseSort(json['sort'] as Map<String, dynamic>),
      reqStats: _parseReqStats(json['reqStats'] as Map<String, dynamic>? ?? {}),
      reqSubstats: _parseReqSubstats(json['reqSubstats'] as Map<String, dynamic>? ?? {}),
      affinites: _parseAffinites(json['affinites'] as List<dynamic>? ?? []),
      role: json['role'] as String?,
      badge: json['badge'] as String?,
      compagnon: json['compagnon'] != null
          ? CompagnonData.fromJson(json['compagnon'] as Map<String, dynamic>)
          : null,
      bonusSoutien: json['bonusSoutien'] != null
          ? _parseBonusSoutien(json['bonusSoutien'] as Map<String, dynamic>)
          : null,
      passifs: _parsePassifs(json['passifs']),
      conditionSpeciale: json['conditionSpeciale'] != null
          ? _parseCondition(json['conditionSpeciale'] as Map<String, dynamic>)
          : null,
    );
  }

  static Sort _parseSort(Map<String, dynamic> json) {
    return Sort(
      id: json['id'] as String,
      nom: json['nom'] as String,
      emoji: json['emoji'] as String? ?? '⚔️',
      type: json['type'] == 'passif' ? SortType.passif : SortType.actif,
      cooldown: json['cooldown'] as int? ?? 0,
      description: json['description'] as String,
      effet: _parseSortEffet(json['effet'] as Map<String, dynamic>),
    );
  }

  static SortEffet _parseSortEffet(Map<String, dynamic> json) {
    return SortEffet(
      typeEffet: _parseSortEffetType(json['typeEffet'] as String),
      statBase: json['statBase'] != null
          ? _parseStat(json['statBase'] as String)
          : null,
      multiplicateur: (json['multiplicateur'] as num?)?.toDouble() ?? 1.0,
      bonusFixe: json['bonusFixe'] as int? ?? 0,
      cible: _parseSortCible(json['cible'] as String? ?? 'ennemicible'),
      duree: json['duree'] as int?,
      declencheur: json['declencheur'] != null
          ? _parseDeclencheur(json['declencheur'] as String)
          : null,
    );
  }

  static Map<StatPrincipale, int> _parseReqStats(Map<String, dynamic> json) {
    return json.map((key, value) => MapEntry(
      _parseStat(key),
      value as int,
    ));
  }

  static Map<Substat, int> _parseReqSubstats(Map<String, dynamic> json) {
    return json.map((key, value) => MapEntry(
      _parseSubstat(key),
      value as int,
    ));
  }

  static List<BatimentType> _parseAffinites(List<dynamic> json) {
    return json
        .map((e) => _parseBatimentType(e as String))
        .whereType<BatimentType>()
        .toList();
  }

  static BonusSoutien? _parseBonusSoutien(Map<String, dynamic> json) {
    return BonusSoutien(
      description: json['description'] as String,
      modificateurs: (json['modificateurs'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      estGlobal: json['estGlobal'] as bool? ?? false,
    );
  }

  static ConditionSpeciale? _parseCondition(Map<String, dynamic> json) {
    final type = json['type'] as String;
    
    return ConditionSpeciale(
      description: json['description'] as String,
      verifier: (merc, etat) {
        switch (type) {
          case 'egalite':
            final stat1 = json['stat1'] as String;
            final stat2 = json['stat2'] as String;
            final v1 = _getStatValue(merc, stat1);
            final v2 = _getStatValue(merc, stat2);
            return v1 == v2;
            
          case 'double_egalite':
            final s1 = json['stat1'] as String;
            final v1 = json['valeur1'] as int;
            final s2 = json['stat2'] as String;
            final v2 = json['valeur2'] as int;
            return _getStatValue(merc, s1) == v1 &&
                   _getStatValue(merc, s2) == v2;
            
          case 'compteur':
            final compteur = json['compteur'] as String;
            final valeur = json['valeur'] as int;
            return _getCompteurValue(merc, compteur) == valeur;
            
          case 'jamais_assigne':
            final jourMin = json['jourMin'] as int? ?? 0;
            return merc.aJamaisEteAssigne && etat.jour >= jourMin;
            
          case 'double_substat':
            final sub1 = json['substat1'] as String;
            final val1 = json['valeur1'] as int;
            final sub2 = json['substat2'] as String;
            final val2 = json['valeur2'] as int;
            return merc.getSubstat(_parseSubstat(sub1)) >= val1 &&
                   merc.getSubstat(_parseSubstat(sub2)) >= val2;
            
          default:
            return false;
        }
      },
    );
  }

  static int _getStatValue(dynamic merc, String stat) {
    switch (stat) {
      case 'niveau': return merc.niveau as int;
      case 'FOR': return merc.stats[StatPrincipale.FOR] ?? 1;
      case 'AGI': return merc.stats[StatPrincipale.AGI] ?? 1;
      case 'INT': return merc.stats[StatPrincipale.INT] ?? 1;
      case 'CON': return merc.stats[StatPrincipale.CON] ?? 1;
      case 'CHA': return merc.stats[StatPrincipale.CHA] ?? 1;
      case 'CHR': return merc.stats[StatPrincipale.CHR] ?? 1;
      case 'PER': return merc.stats[StatPrincipale.PER] ?? 1;
      case 'END': return merc.stats[StatPrincipale.END] ?? 1;
      default: return 0;
    }
  }

  static int _getCompteurValue(dynamic merc, String compteur) {
    switch (compteur) {
      case 'nombreFoisBlesse': return merc.nombreFoisBlesse as int;
      case 'combatsGagnes': return merc.combatsGagnes as int;
      case 'joursConsecutifsDormis': return merc.joursConsecutifsDormis as int;
      default: return 0;
    }
  }

  // ── Parsers d'enum ──
  static ClasseTier _parseTier(String tier) {
    switch (tier) {
      case 'base': return ClasseTier.base;
      case 't1':   return ClasseTier.t1;
      case 't2':   return ClasseTier.t2;
      case 't3':   return ClasseTier.t3;
      case 't4':   return ClasseTier.t4;
      case 'rare': return ClasseTier.rare;
      case 'secret': return ClasseTier.secret;
      default:     return ClasseTier.base;
    }
  }

  static ClasseType _parseType(String type) {
    switch (type) {
      case 'combattant': return ClasseType.combattant;
      case 'civil':      return ClasseType.civil;
      case 'hybride':    return ClasseType.hybride;
      case 'rare':       return ClasseType.rare;
      default:           return ClasseType.combattant;
    }
  }

  static StatPrincipale _parseStat(String stat) {
    switch (stat) {
      case 'FOR': return StatPrincipale.FOR;
      case 'AGI': return StatPrincipale.AGI;
      case 'INT': return StatPrincipale.INT;
      case 'CON': return StatPrincipale.CON;
      case 'CHA': return StatPrincipale.CHA;
      case 'CHR': return StatPrincipale.CHR;
      case 'PER': return StatPrincipale.PER;
      case 'END': return StatPrincipale.END;
      default:    return StatPrincipale.FOR;
    }
  }

  static Substat _parseSubstat(String sub) {
    switch (sub) {
      case 'nature':       return Substat.nature;
      case 'cuisine':      return Substat.cuisine;
      case 'forge':        return Substat.forge;
      case 'erudition':    return Substat.erudition;
      case 'alchimie':     return Substat.alchimie;
      case 'peche':        return Substat.peche;
      case 'tactique':     return Substat.tactique;
      case 'devotion':     return Substat.devotion;
      case 'occultisme':   return Substat.occultisme;
      case 'infiltration': return Substat.infiltration;
      case 'soin':         return Substat.soin;
      case 'commerce':     return Substat.commerce;
      case 'sommeil':      return Substat.sommeil;
      case 'ivresse':      return Substat.ivresse;
      case 'entrainement': return Substat.entrainement;
      default:             return Substat.nature;
    }
  }

  static SortEffetType _parseSortEffetType(String type) {
    switch (type) {
      case 'degatsPhysiques':  return SortEffetType.degatsPhysiques;
      case 'degatsMagiques':   return SortEffetType.degatsMagiques;
      case 'soin':             return SortEffetType.soin;
      case 'buff':             return SortEffetType.buff;
      case 'debuff':           return SortEffetType.debuff;
      case 'invocation':       return SortEffetType.invocation;
      case 'controle':         return SortEffetType.controle;
      case 'execution':        return SortEffetType.execution;
      case 'resurrection':     return SortEffetType.resurrection;
      case 'passifDefense':    return SortEffetType.passifDefense;
      case 'passifAtk':        return SortEffetType.passifAtk;
      case 'passifInit':       return SortEffetType.passifInit;
      default:                 return SortEffetType.degatsPhysiques;
    }
  }

  static SortCible _parseSortCible(String cible) {
    switch (cible) {
      case 'ennemicible':  return SortCible.ennemicible;
      case 'tousEnnemis':  return SortCible.tousEnnemis;
      case 'allieBlesse':  return SortCible.allieBlesse;
      case 'tousAllies':   return SortCible.tousAllies;
      case 'soi':          return SortCible.soi;
      case 'aleatoire':    return SortCible.aleatoire;
      default:             return SortCible.ennemicible;
    }
  }

  static SortDeclencheur? _parseDeclencheur(String d) {
    switch (d) {
      case 'allieBasHP':     return SortDeclencheur.allieBasHP;
      case 'ennemiBassHP':   return SortDeclencheur.ennemiBassHP;
      case 'ennemisGroupes': return SortDeclencheur.ennemisGroupes;
      case 'premierTour':    return SortDeclencheur.premierTour;
      case 'ennemMage':      return SortDeclencheur.ennemMage;
      case 'seulEnCombat':   return SortDeclencheur.seulEnCombat;
      case 'toujours':       return SortDeclencheur.toujours;
      default:               return null;
    }
  }

  static BatimentType? _parseBatimentType(String type) {
    switch (type) {
      case 'foret':            return BatimentType.foret;
      case 'cuisine':          return BatimentType.cuisine;
      case 'forge':            return BatimentType.forge;
      case 'bibliotheque':     return BatimentType.bibliotheque;
      case 'laboratoire':      return BatimentType.laboratoire;
      case 'lac':              return BatimentType.lac;
      case 'tourDeGarde':      return BatimentType.tourDeGarde;
      case 'temple':           return BatimentType.temple;
      case 'siteDeRituel':     return BatimentType.siteDeRituel;
      case 'repaireDesOmbres': return BatimentType.repaireDesOmbres;
      case 'infirmerie':       return BatimentType.infirmerie;
      case 'boutique':         return BatimentType.boutique;
      case 'terrainEntrainement': return BatimentType.terrainEntrainement;
      case 'dortoir':          return BatimentType.dortoir;
      case 'taverne':          return BatimentType.taverne;
      case 'cimetiere':        return BatimentType.cimetiere;
      case 'salleDeJeux':      return BatimentType.salleDeJeux;
      case 'cachot':           return BatimentType.cachot;
      default:                 return null;
    }
  }
}
