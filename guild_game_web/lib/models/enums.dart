// lib/models/enums.dart
// Toutes les énumérations du jeu

enum StatPrincipale {
  FOR, // Force — ATK physique
  AGI, // Agilité — vitesse, esquive
  INT, // Intelligence — magie
  CON, // Constitution — HP max
  CHA, // Chance — critiques
  CHR, // Charisme — commandement
  PER, // Perception — initiative
  END, // Endurance — armure
}

extension StatPrincipaleExt on StatPrincipale {
  String get label {
    switch (this) {
      case StatPrincipale.FOR: return '⚔️ Force';
      case StatPrincipale.AGI: return '💨 Agilité';
      case StatPrincipale.INT: return '🔮 Intelligence';
      case StatPrincipale.CON: return '🛡️ Constitution';
      case StatPrincipale.CHA: return '🎲 Chance';
      case StatPrincipale.CHR: return '💬 Charisme';
      case StatPrincipale.PER: return '👁️ Perception';
      case StatPrincipale.END: return '💪 Endurance';
    }
  }
  String get shortLabel => name;
}

enum Substat {
  nature,       // Forêt
  cuisine,      // Cuisine
  forge,        // Forge
  erudition,    // Bibliothèque
  alchimie,     // Laboratoire
  peche,        // Lac
  tactique,     // Tour de Garde
  devotion,     // Temple
  occultisme,   // Site de Rituel
  infiltration, // Repaire des Ombres
  soin,         // Infirmerie
  commerce,     // Boutique
  sommeil,      // Dortoir (caché)
  ivresse,      // Taverne (caché)
  communion,    // Cimetière (caché)
  isolement,    // Cachot (caché)
  entrainement, // Terrain d'Entraînement
}

extension SubstatExt on Substat {
  String get label {
    switch (this) {
      case Substat.nature:       return '🌿 Nature';
      case Substat.cuisine:      return '🍳 Cuisine';
      case Substat.forge:        return '🔨 Forge';
      case Substat.erudition:    return '📖 Érudition';
      case Substat.alchimie:     return '⚗️ Alchimie';
      case Substat.peche:        return '🎣 Pêche';
      case Substat.tactique:     return '🗺️ Tactique';
      case Substat.devotion:     return '🙏 Dévotion';
      case Substat.occultisme:   return '🕯️ Occultisme';
      case Substat.infiltration: return '🗝️ Infiltration';
      case Substat.soin:         return '🩺 Soin';
      case Substat.commerce:     return '💰 Commerce';
      case Substat.sommeil:      return '🛏️ Sommeil';
      case Substat.ivresse:      return '🍺 Ivresse';
      case Substat.communion:    return '💀 Communion';
      case Substat.isolement:    return '⛓️ Isolement';
      case Substat.entrainement: return '🥊 Entraînement';
    }
  }
}

enum ClasseTier { base, t1, t2, t3, t4, rare, secret }

enum ClasseType { combattant, civil, hybride, rare }

enum SortType { actif, passif }

enum MercenaireSatut {
  libre,    // dans la cour, ne fait rien
  poste,    // assigné à un bâtiment
  combat,   // dans l'équipe de combat
  blesse,   // à l'infirmerie
  critique, // blessé grave, risque de mort
  reve,     // Forme de Rêve active (Dormeur T3+)
}

enum BatimentEtat {
  intact,
  endommage,
  detruit,
  enReparation,
}

enum BatimentType {
  // Bâtiments normaux
  foret,
  cuisine,
  forge,
  bibliotheque,
  laboratoire,
  lac,
  tourDeGarde,
  temple,
  siteDeRituel,
  repaireDesOmbres,
  infirmerie,
  boutique,
  bureauDeRecrutement,
  terrainEntrainement,
  // Bâtiments secrets (découverts via événements)
  dortoir,       // révélé jour 15
  taverne,       // révélé jour 30
  cimetiere,     // événement aléatoire
  salleDeJeux,   // événement aléatoire
  cachot,        // événement aléatoire
  sanctuaireOmbres, // ultra rare
  tourEtoiles,   // ultra rare
  forgeMaudite,  // ultra rare
}

extension BatimentTypeExt on BatimentType {
  bool get estSecret {
    return [
      BatimentType.dortoir,
      BatimentType.taverne,
      BatimentType.cimetiere,
      BatimentType.salleDeJeux,
      BatimentType.cachot,
      BatimentType.sanctuaireOmbres,
      BatimentType.tourEtoiles,
      BatimentType.forgeMaudite,
    ].contains(this);
  }

  Substat? get substat {
    switch (this) {
      case BatimentType.foret:            return Substat.nature;
      case BatimentType.cuisine:          return Substat.cuisine;
      case BatimentType.forge:            return Substat.forge;
      case BatimentType.bibliotheque:     return Substat.erudition;
      case BatimentType.laboratoire:      return Substat.alchimie;
      case BatimentType.lac:              return Substat.peche;
      case BatimentType.tourDeGarde:      return Substat.tactique;
      case BatimentType.temple:           return Substat.devotion;
      case BatimentType.siteDeRituel:     return Substat.occultisme;
      case BatimentType.repaireDesOmbres: return Substat.infiltration;
      case BatimentType.infirmerie:       return Substat.soin;
      case BatimentType.boutique:         return Substat.commerce;
      case BatimentType.terrainEntrainement: return Substat.entrainement;
      case BatimentType.dortoir:          return Substat.sommeil;
      case BatimentType.taverne:          return Substat.ivresse;
      case BatimentType.cimetiere:        return Substat.communion;
      case BatimentType.cachot:           return Substat.isolement;
      default:                            return null;
    }
  }

  String get emoji {
    switch (this) {
      case BatimentType.foret:            return '🌲';
      case BatimentType.cuisine:          return '🍳';
      case BatimentType.forge:            return '🔨';
      case BatimentType.bibliotheque:     return '📚';
      case BatimentType.laboratoire:      return '🧪';
      case BatimentType.lac:              return '🎣';
      case BatimentType.tourDeGarde:      return '🛡️';
      case BatimentType.temple:           return '⛪';
      case BatimentType.siteDeRituel:     return '🕯️';
      case BatimentType.repaireDesOmbres: return '🗝️';
      case BatimentType.infirmerie:       return '🏥';
      case BatimentType.boutique:         return '🏪';
      case BatimentType.bureauDeRecrutement: return '📋';
      case BatimentType.terrainEntrainement: return '⚔️';
      case BatimentType.dortoir:          return '🛏️';
      case BatimentType.taverne:          return '🍺';
      case BatimentType.cimetiere:        return '💀';
      case BatimentType.salleDeJeux:      return '🎰';
      case BatimentType.cachot:           return '⛓️';
      default:                            return '❓';
    }
  }

  String get nom {
    switch (this) {
      case BatimentType.foret:            return 'Forêt Sacrée';
      case BatimentType.cuisine:          return 'Cuisine';
      case BatimentType.forge:            return 'Forge';
      case BatimentType.bibliotheque:     return 'Bibliothèque';
      case BatimentType.laboratoire:      return 'Laboratoire';
      case BatimentType.lac:              return 'Lac de Pêche';
      case BatimentType.tourDeGarde:      return 'Tour de Garde';
      case BatimentType.temple:           return 'Temple';
      case BatimentType.siteDeRituel:     return 'Site de Rituel';
      case BatimentType.repaireDesOmbres: return 'Repaire des Ombres';
      case BatimentType.infirmerie:       return 'Infirmerie';
      case BatimentType.boutique:         return 'Boutique';
      case BatimentType.bureauDeRecrutement: return 'Bureau de Recrutement';
      case BatimentType.terrainEntrainement: return "Terrain d'Entraînement";
      case BatimentType.dortoir:          return 'Dortoir';
      case BatimentType.taverne:          return 'Taverne';
      case BatimentType.cimetiere:        return 'Cimetière';
      case BatimentType.salleDeJeux:      return 'Salle de Jeux';
      case BatimentType.cachot:           return 'Cachot';
      default:                            return '???';
    }
  }

  int get cout {
    switch (this) {
      case BatimentType.foret:            return 80;
      case BatimentType.cuisine:          return 60;
      case BatimentType.forge:            return 100;
      case BatimentType.bibliotheque:     return 90;
      case BatimentType.laboratoire:      return 150;
      case BatimentType.lac:              return 50;
      case BatimentType.tourDeGarde:      return 70;
      case BatimentType.temple:           return 120;
      case BatimentType.siteDeRituel:     return 130;
      case BatimentType.repaireDesOmbres: return 110;
      case BatimentType.infirmerie:       return 80;
      case BatimentType.boutique:         return 90;
      case BatimentType.bureauDeRecrutement: return 0;
      case BatimentType.terrainEntrainement: return 70;
      default:                            return 0;
    }
  }
}

enum RenommeeNiveau {
  ruines,    // Point de départ
  inconnue,  // ⭐
  locale,    // ⭐⭐
  regionale, // ⭐⭐⭐
  reconnue,  // ⭐⭐⭐⭐
  sommet,    // 👑
}

extension RenommeeExt on RenommeeNiveau {
  String get label {
    switch (this) {
      case RenommeeNiveau.ruines:    return '🏚️ Ruines';
      case RenommeeNiveau.inconnue:  return '⭐ Inconnue';
      case RenommeeNiveau.locale:    return '⭐⭐ Locale';
      case RenommeeNiveau.regionale: return '⭐⭐⭐ Régionale';
      case RenommeeNiveau.reconnue:  return '⭐⭐⭐⭐ Reconnue';
      case RenommeeNiveau.sommet:    return '👑 Sommet du Royaume';
    }
  }

  int get maxMercenaires {
    switch (this) {
      case RenommeeNiveau.ruines:    return 5;
      case RenommeeNiveau.inconnue:  return 5;
      case RenommeeNiveau.locale:    return 7;
      case RenommeeNiveau.regionale: return 9;
      case RenommeeNiveau.reconnue:  return 11;
      case RenommeeNiveau.sommet:    return 15;
    }
  }

  int get maxEvenementsParJour {
    switch (this) {
      case RenommeeNiveau.ruines:    return 1;
      case RenommeeNiveau.inconnue:  return 1;
      case RenommeeNiveau.locale:    return 2;
      case RenommeeNiveau.regionale: return 3;
      case RenommeeNiveau.reconnue:  return 4;
      case RenommeeNiveau.sommet:    return 5;
    }
  }

  int get seuilRenommee {
    switch (this) {
      case RenommeeNiveau.ruines:    return 0;
      case RenommeeNiveau.inconnue:  return 10;
      case RenommeeNiveau.locale:    return 50;
      case RenommeeNiveau.regionale: return 150;
      case RenommeeNiveau.reconnue:  return 400;
      case RenommeeNiveau.sommet:    return 1000;
    }
  }
}

enum GraviteBlessure {
  legere,    // 1-2 jours
  moyenne,   // 3-5 jours
  grave,     // 7-10 jours
  critique,  // 14+ jours, risque de mort
}

enum EvenementType {
  fixe,       // Arrive à un jour précis
  poste,      // Lié à l'activité au poste
  aleatoire,  // Aléatoire selon Renommée
  bataille,   // Combat forcé ou défi
  metier,     // Lié au tier du civil
  cosmique,   // Ultra rare
  zone,       // Lié à l'exploration
}

enum ZoneEtat {
  inconnue,   // Pas encore révélée
  mystere,    // Silhouette visible, contenu inconnu
  decouverte, // Première entrée faite, contenu connu
  connue,     // Farmable librement
}

enum TypeEnnemi {
  gobelin,
  orc,
  squelette,
  troll,
  sorcier,
  dragon,
  araignee,
  vampire,
  elementaire,
  bandit,
  boss,
}
