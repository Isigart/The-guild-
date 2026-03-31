# Compagnie de Mercenaires — Squelette Flutter

## Structure du projet

```
lib/
├── main.dart                    # Point d'entrée + routing
├── models/
│   ├── enums.dart              # Toutes les énumérations
│   ├── mercenaire.dart         # Modèle Mercenaire
│   ├── classe.dart             # Modèle Classe + Sort
│   ├── sort.dart               # Modèle Sort + Effets
│   ├── models.dart             # Batiment, Ennemi, Zone, Evenement
│   └── etat_jeu.dart          # État central du jeu
├── systems/
│   └── systems.dart            # Tous les systèmes métier
│       ├── JourneeSystem       # Chef d'orchestre
│       ├── ClasseSystem        # Évolutions de classes
│       ├── ProgressionSystem   # XP, niveaux, stats
│       ├── CampSystem          # Postes, substats, soutien
│       ├── CombatSystem        # Mécanique de combat
│       ├── EvenementSystem     # Événements journaliers
│       └── GenerateurSystem    # Génération de contenu
├── providers/
│   └── game_provider.dart      # Riverpod state management
└── screens/
    └── screens.dart            # Tous les écrans
        ├── TitreScreen         # Écran titre
        ├── IntroScreen         # Texte narratif + nom guilde
        ├── GuildeScreen        # Hub principal (plan vue dessus)
        ├── FicheMercenaireScreen # Fiche détaillée mercenaire
        └── SelectionEquipeScreen # Choix des 5 combattants
```

## Installation

```bash
flutter pub get
flutter run
```

## Systèmes à implémenter (TODO)

### Priorité 1 — Fonctionnel de base
- [ ] Base de données des classes (ClasseSystem)
- [ ] Base de données des événements (EvenementSystem)
- [ ] Plan de guilde 2D (CustomPainter)
- [ ] Écran de combat avec canvas 2D
- [ ] Sauvegarde SQLite

### Priorité 2 — Gameplay complet  
- [ ] Système de zones et exploration
- [ ] Générateur d'ennemis avec résistances
- [ ] Bureau de recrutement
- [ ] Boutique
- [ ] Bâtiments secrets (dortoir, taverne...)

### Priorité 3 — Profondeur
- [ ] Classes rares et conditions spéciales
- [ ] Forme de Rêve (Dormeur T3+)
- [ ] Guildes rivales
- [ ] Événements cosmiques
- [ ] Système de renommée complet

## Architecture

L'état central `EtatJeu` est la **source unique de vérité**.
Les systèmes ne communiquent pas entre eux — tout passe par `EtatJeu`.
Riverpod gère la réactivité de l'UI.

```
UI → Provider → System → EtatJeu → UI (rebuild)
```

## Données de jeu

Les données (classes, événements, ennemis) seront dans `assets/data/` :
- `classes.json` — toutes les classes avec prérequis
- `evenements.json` — bibliothèque d'événements  
- `ennemis.json` — templates d'ennemis par zone
- `zones.json` — définition des zones
