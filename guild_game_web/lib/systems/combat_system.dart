// lib/systems/combat_system.dart
// Système de combat complet
// 1 tick = 1 action = 1 acteur agit
// Ordre par initiative — héros et ennemis mélangés

import 'dart:math';
import '../models/enums.dart';
import '../models/mercenaire.dart';
import '../models/models.dart';
import '../models/sort.dart';
import '../models/combat_models.dart';
import '../models/passif_civil.dart';
import 'generateur_system.dart';

class CombatSystem {
  final GenerateurSystem generateurSystem;
  final Random _rng = Random();

  CombatSystem({required this.generateurSystem});

  // ══════════════════════════════════════════════════════
  // INITIALISATION
  // ══════════════════════════════════════════════════════

  EtatCombat initialiserCombat({
    required List<Mercenaire> equipe,
    required Zone zone,
    required PassifsResult passifs,
    bool estBoss = false,
    bool fuiteInterdite = false,
  }) {
    final heroes = equipe.map((m) => _creerCombattant(m, passifs)).toList();
    final ennemisRaw = generateurSystem.genererEnnemis(zone, estBoss: estBoss);
    final ennemis = ennemisRaw.map(_creerEnnemiCombat).toList();
    _appliquerBuffsAvantCombat(heroes, ennemis, passifs);

    return EtatCombat(
      heroes: heroes,
      ennemis: ennemis,
      tick: 0,
    );
  }

  // ── Créer combattant ──
  CombattantCombat _creerCombattant(Mercenaire m, PassifsResult passifs) {
    final role = m.classeActuelle.role ?? 'melee_physique';
    final hpMax  = (m.hpMax * (1.0 + passifs.hpMax)).round();
    final atk    = (m.atk   * (1.0 + passifs.atk)).round();
    final mag    = (m.atkMagique * (1.0 + passifs.degatsMagiques)).round();
    // Compagnon animal — dérivé de la classe
    Invocation? compagnon;
    final compagnonData = m.classeActuelle.compagnon;
    if (compagnonData != null) {
      compagnon = Invocation(
        id:            'compagnon_${m.id}',
        nom:           compagnonData.nom,
        emoji:         compagnonData.emoji,
        presence:      TypePresence.physique,
        hp:            (hpMax * compagnonData.hpMulti).round().clamp(1, 99999),
        hpMax:         (hpMax * compagnonData.hpMulti).round().clamp(1, 99999),
        atk:           (atk  * compagnonData.atkMulti).round().clamp(1, 99999),
        initiative:    compagnonData.initiative,
        roundsRestants: -1, // permanent
        maitreId:      m.id,
        role:          'melee_physique',
      );
    }

    return CombattantCombat(
      mercenaire:       m,
      hpCombat:         hpMax,
      hpMaxCombat:      hpMax,
      atkCombat:        atk,
      atkMagiqueCombat: mag,
      armureCombat:     m.armure,
      initiativeCombat: _calcInit(m, passifs),
      position:         positionDuRole(role),
      role:             role,
      resistances:      _resistancesHeros(role, m),
      compagnon:        compagnon,
    );
  }

  int _calcInit(Mercenaire m, PassifsResult p) =>
      (m.stats[StatPrincipale.AGI] ?? 1) +
      (m.stats[StatPrincipale.PER] ?? 1) ~/ 2 +
      p.initiative.round();

  Resistances _resistancesHeros(String role, Mercenaire m) {
    final v = <TypeDegats, double>{};
    if (role == 'protecteur')      v[TypeDegats.physique] = 0.25;
    if (role == 'melee_physique')  v[TypeDegats.physique] = 0.10;
    if (role == 'distance_magique')v[TypeDegats.magique]  = 0.10;
    final dev  = m.substats[Substat.devotion]     ?? 0;
    final nat  = m.substats[Substat.nature]       ?? 0;
    final iso  = m.substats[Substat.isolement]    ?? 0;
    final ivre = m.substats[Substat.ivresse]      ?? 0;
    if (dev  >= 20) v[TypeDegats.controle]       = (v[TypeDegats.controle]       ?? 0) + 0.25;
    if (dev  >= 50) v[TypeDegats.effetsNefastes] = (v[TypeDegats.effetsNefastes] ?? 0) + 0.25;
    if (nat  >= 20) v[TypeDegats.poison]         = (v[TypeDegats.poison]         ?? 0) + 0.25;
    if (iso  >= 30) v[TypeDegats.controle]       = ((v[TypeDegats.controle] ?? 0) + 0.50).clamp(-2.0, 0.90);
    if (ivre >= 30) v[TypeDegats.poison]         = ((v[TypeDegats.poison]   ?? 0) + 0.50).clamp(-2.0, 0.90);
    for (final k in v.keys) v[k] = v[k]!.clamp(-2.0, 0.90);
    return Resistances(v);
  }

  EnnemiCombat _creerEnnemiCombat(Ennemi e) => EnnemiCombat(
    id: e.id, nom: e.nom, emoji: e.emoji,
    role:       _roleEnnemi(e.type),
    position:   _posEnnemi(e.type),
    hp: e.hpMax, hpMax: e.hpMax,
    atk: e.atk, atkMagique: e.atk ~/ 2,
    initiative:  e.initiative,
    resistances: _resEnnemi(e.type),
  );

  Resistances _resEnnemi(TypeEnnemi t) {
    switch (t) {
      case TypeEnnemi.gobelin:   return Resistances({TypeDegats.magique: 0.50,  TypeDegats.physique: -0.25});
      case TypeEnnemi.orc:       return Resistances({TypeDegats.physique: 0.50, TypeDegats.magique: -0.50});
      case TypeEnnemi.squelette: return Resistances({TypeDegats.poison: 0.90,   TypeDegats.tranchant: 0.50, TypeDegats.contondant: -0.50});
      case TypeEnnemi.troll:     return Resistances({TypeDegats.physique: 0.60, TypeDegats.feu: -0.80});
      case TypeEnnemi.sorcier:   return Resistances({TypeDegats.magique: 0.30,  TypeDegats.physique: -0.60});
      case TypeEnnemi.dragon:    return Resistances({TypeDegats.feu: 0.90,      TypeDegats.physique: 0.50, TypeDegats.glace: -1.0});
      case TypeEnnemi.araignee:  return Resistances({TypeDegats.poison: 0.90,   TypeDegats.feu: -0.50});
      case TypeEnnemi.vampire:   return Resistances({TypeDegats.poison: 0.90,   TypeDegats.physique: 0.50, TypeDegats.sacre: -1.50});
      default:                   return Resistances({});
    }
  }

  String _roleEnnemi(TypeEnnemi t) {
    if (t == TypeEnnemi.sorcier) return 'distance_magique';
    if (t == TypeEnnemi.vampire || t == TypeEnnemi.araignee) return 'opportuniste';
    if (t == TypeEnnemi.troll) return 'protecteur';
    return 'melee_physique';
  }

  Position _posEnnemi(TypeEnnemi t) {
    if (t == TypeEnnemi.sorcier)  return Position.arriere;
    if (t == TypeEnnemi.vampire)  return Position.milieu;
    if (t == TypeEnnemi.araignee) return Position.milieu;
    return Position.avant;
  }

  void _appliquerBuffsAvantCombat(
    List<CombattantCombat> heroes,
    List<EnnemiCombat> ennemis,
    PassifsResult p,
  ) {
    for (final h in heroes) {
      if (p.immunitePoison)   h.ajouterEffet(EffetStatut(type: TypeEffetStatut.immunitePoison,        roundsRestants: 999, sourceId: 'passif'));
      if (p.immunitePeur)     h.ajouterEffet(EffetStatut(type: TypeEffetStatut.peur,                  roundsRestants: 999, sourceId: 'passif'));
      if (p.immuniteEffets)   h.ajouterEffet(EffetStatut(type: TypeEffetStatut.immuniteEffetsNefastes, roundsRestants: 999, sourceId: 'passif'));
      if (p.rageSacree)       h.ajouterEffet(EffetStatut(type: TypeEffetStatut.rage,                  roundsRestants: 3, valeur: 0.30, sourceId: 'passif'));
    }
    if (p.empoisonnementInitial) {
      for (final e in ennemis) {
        e.ajouterEffet(EffetStatut(type: TypeEffetStatut.poison, roundsRestants: 5, valeur: 0.05, sourceId: 'passif'));
      }
    }
  }

  // ══════════════════════════════════════════════════════
  // ORDRE D'INITIATIVE
  // ══════════════════════════════════════════════════════

  List<dynamic> _ordre(EtatCombat etat) {
    final acteurs = <dynamic>[
      ...etat.heroesVivants,
      ...etat.ennemisVivants,
      ...etat.invocationsActives_.where((i) => i.presence == TypePresence.physique),
    ];
    acteurs.sort((a, b) {
      final ia = _init(a) + _rng.nextInt(3);
      final ib = _init(b) + _rng.nextInt(3);
      return ib.compareTo(ia);
    });
    // Insérer compagnons juste après leur maître
    final resultat = <dynamic>[];
    for (final a in acteurs) {
      resultat.add(a);
      if (a is CombattantCombat && a.compagnon != null && a.compagnon!.estActif) {
        resultat.add(_CompEntree(a.compagnon!, a));
      }
    }
    return resultat;
  }

  int _init(dynamic a) {
    if (a is CombattantCombat) return a.initiativeCombat;
    if (a is EnnemiCombat)     return a.initiative;
    if (a is Invocation)       return a.initiative;
    if (a is _CompEntree)      return a.comp.initiative;
    return 0;
  }

  // ══════════════════════════════════════════════════════
  // EXÉCUTER UN TICK
  // ══════════════════════════════════════════════════════

  EtatCombat executerTick(EtatCombat etat) {
    if (etat.termine) return etat;
    etat.actionsTickActuel.clear();
    etat.tick++;

    // Limite max
    if (etat.tickLimiteAtteinte) {
      etat.termine = true; etat.victoire = false;
      etat.actionsTickActuel.add(ActionCombat(acteurNom: 'Destin', acteurEmoji: '⚖️', typeAction: 'annonce', description: 'Épuisement — défaite.'));
      return etat;
    }

    final ordre = _ordre(etat);
    if (ordre.isEmpty) return _fin(etat);

    final acteur = ordre[(etat.tick - 1) % ordre.length];

    // Tick effets avant d'agir
    _tickEffets(acteur, etat);

    // Action
    if (acteur is CombattantCombat && acteur.estVivant) {
      _agirHeros(acteur, etat);
    } else if (acteur is EnnemiCombat && acteur.estVivant) {
      _agirEnnemi(acteur, etat);
    } else if (acteur is _CompEntree && acteur.comp.estActif) {
      _agirCompagnon(acteur.comp, acteur.maitre, etat);
    } else if (acteur is Invocation && acteur.estActif) {
      _agirInvocation(acteur, etat);
    }

    // Tick invocations temporaires
    etat.invocationsActives.removeWhere((i) {
      if (i.estPermanent) return false;
      i.roundsRestants--;
      return i.roundsRestants <= 0;
    });

    // Tick agro
    if (etat.agroRoundsRestants > 0) {
      etat.agroRoundsRestants--;
      if (etat.agroRoundsRestants <= 0) etat.agroForceSurId = null;
    }

    return _fin(etat);
  }

  void _tickEffets(dynamic acteur, EtatCombat etat) {
    int degats = 0;
    if (acteur is CombattantCombat) {
      degats = acteur.tickEffets();
      if (degats > 0) {
        acteur.hpCombat = (acteur.hpCombat - degats).clamp(0, acteur.hpMaxCombat);
        if (acteur.hpCombat <= 0) acteur.estAgenouille = true;
        etat.actionsTickActuel.add(ActionCombat(acteurNom: acteur.nom, acteurEmoji: acteur.emoji, typeAction: 'dot', valeur: degats, effetApplique: 'DoT'));
      }
    } else if (acteur is EnnemiCombat) {
      degats = acteur.tickEffets();
      if (degats > 0) {
        acteur.hp = (acteur.hp - degats).clamp(0, acteur.hpMax);
        if (acteur.hp <= 0) acteur.estVaincu = true;
        etat.actionsTickActuel.add(ActionCombat(acteurNom: acteur.nom, acteurEmoji: acteur.emoji, typeAction: 'dot', valeur: degats, effetApplique: 'Poison'));
      }
    }
  }

  // ══════════════════════════════════════════════════════
  // ACTIONS HÉROS
  // ══════════════════════════════════════════════════════

  void _agirHeros(CombattantCombat h, EtatCombat etat) {
    if (h.estParalyse) { _annoncer(h.nom, h.emoji, '${h.nom} est paralysé !', etat); return; }
    if (h.estConfus)   { _attaqueConfuse(h, etat); return; }

    switch (h.role) {
      case 'soigneur':      _roSoigneur(h, etat);
      case 'soutien':       _roSoutien(h, etat);
      case 'controle':      _roControle(h, etat);
      case 'effet_nefaste': _roEffetNefaste(h, etat);
      case 'invocateur':    _roInvocateur(h, etat);
      case 'opportuniste':  _roOpportuniste(h, etat);
      case 'protecteur':    _roProtecteur(h, etat);
      default:              _roDPS(h, etat);
    }
  }

  void _roSoigneur(CombattantCombat h, EtatCombat etat) {
    final blesse = _plusBlesse(etat);
    if (blesse != null && blesse.hpCombat < blesse.hpMaxCombat * 0.90) {
      final s = _sort(h, SortEffetType.soin);
      if (s != null) { _lancerSort(h, s, etat); return; }
      final montant = (h.atkMagiqueCombat * 0.8).round().clamp(1, 99999);
      final soin = blesse.recevoirSoin(montant);
      etat.actionsTickActuel.add(ActionCombat(acteurNom: h.nom, acteurEmoji: h.emoji, cibleNom: blesse.nom, typeAction: 'soin', valeur: soin));
    } else { _attaque(h, etat); }
  }

  void _roSoutien(CombattantCombat h, EtatCombat etat) {
    final s = _sort(h, SortEffetType.buff);
    if (s != null) _lancerSort(h, s, etat); else _attaque(h, etat);
  }

  void _roControle(CombattantCombat h, EtatCombat etat) {
    final s = _sort(h, SortEffetType.controle) ?? _sort(h, SortEffetType.debuff);
    if (s != null) _lancerSort(h, s, etat); else _attaque(h, etat);
  }

  void _roEffetNefaste(CombattantCombat h, EtatCombat etat) {
    final s = _sort(h, SortEffetType.poison) ?? _sort(h, SortEffetType.debuff);
    if (s != null) _lancerSort(h, s, etat); else _attaque(h, etat);
  }

  void _roInvocateur(CombattantCombat h, EtatCombat etat) {
    final s = _sort(h, SortEffetType.invocation);
    if (s != null && etat.invocationsActives.length < 4) _lancerSort(h, s, etat);
    else _attaque(h, etat);
  }

  void _roOpportuniste(CombattantCombat h, EtatCombat etat) {
    if (etat.tick <= 2) {
      h.ajouterEffet(EffetStatut(type: TypeEffetStatut.concentration, roundsRestants: 1, valeur: 2.0, sourceId: h.id));
      _annoncer(h.nom, h.emoji, '${h.nom} se concentre...', etat);
      return;
    }
    final s = _sort(h, SortEffetType.execution);
    final faible = etat.ennemisVivants.where((e) => e.hp < e.hpMax * 0.20).firstOrNull;
    if (s != null && faible != null) { _lancerSort(h, s, etat); return; }
    final multi = h.aEffet(TypeEffetStatut.concentration) ? 2.0 : 1.0;
    _attaque(h, etat, multi: multi);
  }

  void _roProtecteur(CombattantCombat h, EtatCombat etat) {
    if (etat.agroForceSurId == null) {
      etat.agroForceSurId = h.id;
      etat.agroRoundsRestants = 3;
      h.porteurAgro = true;
    }
    final s = _sort(h, SortEffetType.bouclier) ?? _sort(h, SortEffetType.buff);
    if (s != null) _lancerSort(h, s, etat); else _attaque(h, etat);
  }

  void _roDPS(CombattantCombat h, EtatCombat etat) {
    final s = _sortOffensif(h, etat);
    if (s != null) _lancerSort(h, s, etat); else _attaque(h, etat);
  }

  // ══════════════════════════════════════════════════════
  // ATTAQUE BASIQUE
  // ══════════════════════════════════════════════════════

  void _attaque(CombattantCombat h, EtatCombat etat, {double multi = 1.0}) {
    final cibles = etat.ennemisCiblables(h.role);
    if (cibles.isEmpty) return;
    final cible = cibles.reduce((a, b) => a.hp < b.hp ? a : b);

    final magique = h.role == 'melee_magique' || h.role == 'distance_magique';
    final typeDeg = magique ? TypeDegats.magique : TypeDegats.physique;
    final atkBase = magique ? h.atkMagiqueCombat : h.atkCombat;

    double m = multi;
    if (h.estEnRage) {
      final rage = h.effets.firstWhere((e) => e.type == TypeEffetStatut.rage);
      m *= (1.0 + rage.valeur);
    }

    int degats = (atkBase * m).round();
    final crit = _rng.nextDouble() < h.mercenaire.chanceCritique;
    if (crit) degats = (degats * 2).round();

    final inflige = cible.recevoirDegats(degats, typeDeg);
    etat.actionsTickActuel.add(ActionCombat(
      acteurNom: h.nom, acteurEmoji: h.emoji, cibleNom: cible.nom,
      typeAction: 'attaque', valeur: inflige, estCritique: crit,
    ));
    if (!cible.estVivant) etat.actionsTickActuel.add(ActionCombat(acteurNom: cible.nom, acteurEmoji: cible.emoji, typeAction: 'mort'));
  }

  void _attaqueConfuse(CombattantCombat h, EtatCombat etat) {
    final tous = [...etat.heroesVivants.where((x) => x.id != h.id), ...etat.ennemisVivants];
    if (tous.isEmpty) return;
    final cible = tous[_rng.nextInt(tous.length)];
    final degats = (h.atkCombat * 0.7).round();
    if (cible is CombattantCombat) {
      cible.recevoirDegats(degats, TypeDegats.physique);
    } else if (cible is EnnemiCombat) {
      cible.recevoirDegats(degats, TypeDegats.physique);
    }
    etat.actionsTickActuel.add(ActionCombat(acteurNom: h.nom, acteurEmoji: h.emoji, cibleNom: '???', typeAction: 'attaque', valeur: degats, description: '😵 CONFUS'));
  }

  // ══════════════════════════════════════════════════════
  // SORTS
  // ══════════════════════════════════════════════════════

  void _lancerSort(CombattantCombat lanceur, Sort sort, EtatCombat etat) {
    switch (sort.effet.typeEffet) {
      case SortEffetType.degatsPhysiques: _sDegats(lanceur, sort, etat, TypeDegats.physique);
      case SortEffetType.degatsMagiques:  _sDegats(lanceur, sort, etat, TypeDegats.magique);
      case SortEffetType.soin:            _sSoin(lanceur, sort, etat);
      case SortEffetType.buff:            _sBuff(lanceur, sort, etat);
      case SortEffetType.debuff:          _sDebuff(lanceur, sort, etat, TypeEffetStatut.affaiblissement);
      case SortEffetType.controle:        _sDebuff(lanceur, sort, etat, TypeEffetStatut.paralysie);
      case SortEffetType.poison:          _sDebuff(lanceur, sort, etat, TypeEffetStatut.poison);
      case SortEffetType.invocation:      _sInvocation(lanceur, sort, etat);
      case SortEffetType.execution:       _sExecution(lanceur, sort, etat);
      case SortEffetType.drain:           _sDrain(lanceur, sort, etat);
      default: _annoncer(lanceur.nom, lanceur.emoji, '${sort.emoji} ${sort.nom}', etat);
    }
    sort.cooldownActuel = sort.cooldown;
  }

  void _sDegats(CombattantCombat l, Sort s, EtatCombat etat, TypeDegats type) {
    final cibles = _cibles(s.effet.cible, l, etat);
    final statV = s.effet.statBase != null ? (l.mercenaire.stats[_stat(s.effet.statBase!)] ?? 1) : l.atkCombat;
    for (final c in cibles) {
      int d = (statV * s.effet.multiplicateur + s.effet.bonusFixe).round();
      if (l.aEffet(TypeEffetStatut.concentration)) { d *= 2; l.effets.removeWhere((e) => e.type == TypeEffetStatut.concentration); }
      final inflige = c is EnnemiCombat ? c.recevoirDegats(d, type) : (c as CombattantCombat).recevoirDegats(d, type);
      final nomC = c is EnnemiCombat ? c.nom : (c as CombattantCombat).nom;
      etat.actionsTickActuel.add(ActionCombat(acteurNom: l.nom, acteurEmoji: l.emoji, cibleNom: nomC, typeAction: 'sort', valeur: inflige, description: '${s.emoji} ${s.nom}'));
      if (c is EnnemiCombat && !c.estVivant) etat.actionsTickActuel.add(ActionCombat(acteurNom: c.nom, acteurEmoji: c.emoji, typeAction: 'mort'));
    }
  }

  void _sSoin(CombattantCombat l, Sort s, EtatCombat etat) {
    final cibles = _cibles(s.effet.cible, l, etat);
    for (final c in cibles) {
      if (c is CombattantCombat && c.estVivant) {
        final m = (c.hpMaxCombat * s.effet.multiplicateur + l.atkMagiqueCombat * 0.3).round();
        final soin = c.recevoirSoin(m);
        etat.actionsTickActuel.add(ActionCombat(acteurNom: l.nom, acteurEmoji: l.emoji, cibleNom: c.nom, typeAction: 'soin', valeur: soin));
      }
    }
  }

  void _sBuff(CombattantCombat l, Sort s, EtatCombat etat) {
    final duree = s.effet.duree ?? 3;
    final cibles = _cibles(s.effet.cible, l, etat);
    for (final c in cibles) {
      if (c is CombattantCombat) {
        c.ajouterEffet(EffetStatut(type: TypeEffetStatut.rage, roundsRestants: duree, valeur: s.effet.multiplicateur, sourceId: l.id));
      }
    }
    _annoncer(l.nom, l.emoji, '${s.emoji} ${s.nom} — ${duree}T', etat);
  }

  void _sDebuff(CombattantCombat l, Sort s, EtatCombat etat, TypeEffetStatut effetType) {
    final duree = s.effet.duree ?? 2;
    final cibles = _cibles(s.effet.cible, l, etat);
    for (final c in cibles) {
      if (c is EnnemiCombat) {
        c.ajouterEffet(EffetStatut(type: effetType, roundsRestants: duree, valeur: s.effet.multiplicateur, sourceId: l.id));
        etat.actionsTickActuel.add(ActionCombat(acteurNom: l.nom, acteurEmoji: l.emoji, cibleNom: c.nom, typeAction: 'effet', effetApplique: '${s.emoji} ${s.nom}'));
      }
    }
  }

  void _sInvocation(CombattantCombat l, Sort s, EtatCombat etat) {
    final inv = Invocation(
      id: 'inv_${l.id}_${etat.tick}', nom: s.nom, emoji: s.emoji,
      presence: TypePresence.physique,
      hp: l.atkMagiqueCombat * 2, hpMax: l.atkMagiqueCombat * 2,
      atk: (l.atkMagiqueCombat * s.effet.multiplicateur).round(),
      initiative: l.initiativeCombat ~/ 2,
      roundsRestants: s.effet.duree ?? 3,
      maitreId: l.id,
    );
    etat.invocationsActives.add(inv);
    _annoncer(l.nom, l.emoji, '${inv.emoji} ${inv.nom} invoqué !', etat);
  }

  void _sExecution(CombattantCombat l, Sort s, EtatCombat etat) {
    final cible = etat.ennemisVivants.where((e) => e.hp < e.hpMax * 0.20 && e.estCiblable).firstOrNull;
    if (cible != null) {
      cible.hp = 0; cible.estVaincu = true;
      etat.actionsTickActuel.add(ActionCombat(acteurNom: l.nom, acteurEmoji: l.emoji, cibleNom: cible.nom, typeAction: 'sort', description: '${s.emoji} EXÉCUTION !'));
    } else { _attaque(l, etat); }
  }

  void _sDrain(CombattantCombat l, Sort s, EtatCombat etat) {
    final cibles = _cibles(s.effet.cible, l, etat);
    for (final c in cibles) {
      if (c is EnnemiCombat && c.estVivant) {
        final vol = (c.hpMax * s.effet.multiplicateur).round().clamp(1, 99999);
        c.recevoirDegats(vol, TypeDegats.sombre);
        l.recevoirSoin(vol);
        etat.actionsTickActuel.add(ActionCombat(acteurNom: l.nom, acteurEmoji: l.emoji, cibleNom: c.nom, typeAction: 'sort', valeur: vol, description: '${s.emoji} Drain'));
      }
    }
  }

  // ══════════════════════════════════════════════════════
  // ACTIONS ENNEMIS
  // ══════════════════════════════════════════════════════

  void _agirEnnemi(EnnemiCombat e, EtatCombat etat) {
    if (e.estParalyse) { _annoncer(e.nom, e.emoji, '${e.nom} est paralysé !', etat); return; }
    if (e.estConfus) {
      final allies = etat.ennemisVivants.where((x) => x.id != e.id).toList();
      if (allies.isNotEmpty) {
        final c = allies[_rng.nextInt(allies.length)];
        c.recevoirDegats(e.atk, TypeDegats.physique);
        etat.actionsTickActuel.add(ActionCombat(acteurNom: e.nom, acteurEmoji: e.emoji, cibleNom: c.nom, typeAction: 'attaque', valeur: e.atk, description: '😵 CONFUS'));
        return;
      }
    }

    // Annoncer capa spéciale un tour à l'avance
    if (e.capaSpecialeEnPreparation != null) {
      e.ticksAvantCapa--;
      if (e.ticksAvantCapa <= 0) {
        _execCapa(e, etat);
        e.capaSpecialeEnPreparation = null;
        return;
      }
    } else if (_rng.nextInt(10) < 2) {
      e.capaSpecialeEnPreparation = 'Attaque dévastatrice';
      e.ticksAvantCapa = 2;
      _annoncer(e.nom, e.emoji, '⚡ ${e.nom} prépare ${e.capaSpecialeEnPreparation}...', etat);
      return;
    }

    // Attaque normale selon position
    final cibles = etat.heroesCiblables(e.position);
    if (cibles.isEmpty) return;
    final cible = cibles.reduce((a, b) => a.hpCombat < b.hpCombat ? a : b);
    final magique = e.role == 'distance_magique';
    final atkV = magique ? e.atkMagique : e.atk;
    final typeDeg = magique ? TypeDegats.magique : TypeDegats.physique;
    final inflige = cible.recevoirDegats(atkV, typeDeg);
    etat.actionsTickActuel.add(ActionCombat(acteurNom: e.nom, acteurEmoji: e.emoji, cibleNom: cible.nom, typeAction: 'attaque', valeur: inflige));
    if (!cible.estVivant) etat.actionsTickActuel.add(ActionCombat(acteurNom: cible.nom, acteurEmoji: cible.emoji, typeAction: 'mort'));
  }

  void _execCapa(EnnemiCombat e, EtatCombat etat) {
    for (final h in etat.heroesVivants) {
      final d = h.recevoirDegats((e.atk * 1.5).round(), TypeDegats.physique);
      etat.actionsTickActuel.add(ActionCombat(acteurNom: e.nom, acteurEmoji: e.emoji, cibleNom: h.nom, typeAction: 'attaque', valeur: d, description: '⚡ Attaque dévastatrice'));
    }
  }

  void _agirCompagnon(Invocation comp, CombattantCombat maitre, EtatCombat etat) {
    final cibles = etat.ennemisCiblables(maitre.role);
    if (cibles.isEmpty) return;
    final cible = cibles.reduce((a, b) => a.hp < b.hp ? a : b);
    final d = cible.recevoirDegats(comp.atk, TypeDegats.physique);
    etat.actionsTickActuel.add(ActionCombat(acteurNom: comp.nom, acteurEmoji: comp.emoji, cibleNom: cible.nom, typeAction: 'attaque', valeur: d));
    if (comp.hp <= 0) comp.estAssomme = true;
  }

  void _agirInvocation(Invocation inv, EtatCombat etat) {
    final cibles = etat.ennemisVivants.where((e) => e.estCiblable).toList();
    if (cibles.isEmpty) return;
    final cible = cibles.reduce((a, b) => a.hp < b.hp ? a : b);
    final d = cible.recevoirDegats(inv.atk, TypeDegats.physique);
    etat.actionsTickActuel.add(ActionCombat(acteurNom: inv.nom, acteurEmoji: inv.emoji, cibleNom: cible.nom, typeAction: 'attaque', valeur: d));
  }

  // ══════════════════════════════════════════════════════
  // FUITE
  // ══════════════════════════════════════════════════════

  EtatCombat fuir(EtatCombat etat) {
    etat.termine = true; etat.victoire = false; etat.fuite = true;
    etat.actionsTickActuel.add(ActionCombat(acteurNom: 'Équipe', acteurEmoji: '🚪', typeAction: 'fuite'));
    return etat;
  }

  // ══════════════════════════════════════════════════════
  // FIN & RÉSULTAT
  // ══════════════════════════════════════════════════════

  EtatCombat _fin(EtatCombat etat) {
    if (etat.ennemisVivants.isEmpty || etat.heroesVivants.isEmpty) {
      etat.termine = true;
      etat.victoire = etat.ennemisVivants.isEmpty;
      _annoncer('Combat', '⚔️', etat.victoire ? '✦ Victoire !' : '💀 Défaite...', etat);
    }
    return etat;
  }

  ResultatCombat calculerResultat(EtatCombat etat, Zone zone) {
    if (etat.fuite) return ResultatCombat(victoire: false, fuite: true, orGagne: 0, renommeeGagnee: 0, ticksTotal: etat.tick, xpParMercenaire: {}, blessuresParMercenaire: {}, mercenahiresMonteNiveau: []);

    final xp = <String, int>{};
    final bless = <String, GraviteBlessure?>{};
    int or_ = 0, ren = 0;

    if (etat.victoire) {
      or_ = zone.orBase + _rng.nextInt(zone.orBonus + 1);
      ren = 10 + (zone.difficulte ?? 1) * 5;
      for (final h in etat.heroes) {
        xp[h.id] = 20 + (zone.difficulte ?? 1) * 10;
        if (!h.estVivant)                                    bless[h.id] = _gravite();
        else if (h.hpCombat < h.hpMaxCombat * 0.10)        bless[h.id] = GraviteBlessure.legere;
      }
    } else {
      for (final h in etat.heroes) {
        if (!h.estVivant)                                    bless[h.id] = _gravite();
        else if (h.hpCombat < h.hpMaxCombat * 0.30)        bless[h.id] = GraviteBlessure.legere;
      }
    }

    return ResultatCombat(
      victoire: etat.victoire, orGagne: or_, renommeeGagnee: ren,
      ticksTotal: etat.tick, xpParMercenaire: xp,
      blessuresParMercenaire: bless, mercenahiresMonteNiveau: [],
    );
  }

  GraviteBlessure _gravite() {
    final r = _rng.nextInt(100);
    if (r < 50) return GraviteBlessure.legere;
    if (r < 80) return GraviteBlessure.moyenne;
    if (r < 95) return GraviteBlessure.grave;
    return GraviteBlessure.critique;
  }

  // ══════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════

  Sort? _sort(CombattantCombat h, SortEffetType type) =>
      h.mercenaire.sortsActifs
          .where((s) => s.type == SortType.actif && s.effet.typeEffet == type && (s.cooldownActuel ?? 0) <= 0)
          .firstOrNull;

  Sort? _sortOffensif(CombattantCombat h, EtatCombat etat) {
    for (final t in [SortEffetType.degatsPhysiques, SortEffetType.degatsMagiques, SortEffetType.execution, SortEffetType.drain]) {
      final s = _sort(h, t);
      if (s != null) return s;
    }
    return null;
  }

  List<dynamic> _cibles(SortCible cible, CombattantCombat l, EtatCombat etat) {
    switch (cible) {
      case SortCible.ennemicible:
        final v = etat.ennemisCiblables(l.role);
        return v.isEmpty ? [] : [v.reduce((a, b) => a.hp < b.hp ? a : b)];
      case SortCible.tousEnnemis:   return etat.ennemisVivants;
      case SortCible.allieBlesse:   final b = _plusBlesse(etat); return b != null ? [b] : [];
      case SortCible.tousAllies:    return etat.heroesVivants;
      case SortCible.soi:           return [l];
      case SortCible.aleatoire:
        final v = etat.ennemisVivants;
        return v.isEmpty ? [] : [v[_rng.nextInt(v.length)]];
    }
  }

  CombattantCombat? _plusBlesse(EtatCombat etat) {
    final v = etat.heroesVivants;
    if (v.isEmpty) return null;
    return v.reduce((a, b) => (a.hpCombat / a.hpMaxCombat) < (b.hpCombat / b.hpMaxCombat) ? a : b);
  }

  StatPrincipale _stat(String s) => StatPrincipale.values.firstWhere(
    (v) => v.name == s.toUpperCase(), orElse: () => StatPrincipale.FOR);

  void _annoncer(String nom, String emoji, String msg, EtatCombat etat) =>
      etat.actionsTickActuel.add(ActionCombat(acteurNom: nom, acteurEmoji: emoji, typeAction: 'annonce', description: msg));
}

class _CompEntree {
  final Invocation comp;
  final CombattantCombat maitre;
  const _CompEntree(this.comp, this.maitre);
}
