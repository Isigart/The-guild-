// lib/data/database.dart
// Sauvegarde Web — shared_preferences (JSON)
// Remplace SQLite pour compatibilité navigateur

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/etat_jeu.dart';
import '../models/mercenaire.dart';
import '../models/models.dart';
import '../models/enums.dart';
import '../models/classe.dart';
import '../models/objet.dart';

class GameDatabase {
  static const _kPartie    = 'ggame_partie';
  static const _kMercs     = 'ggame_mercs';
  static const _kBats      = 'ggame_bats';
  static const _kEquipe    = 'ggame_equipe';

  // ══════════════════════════════════════════════════════
  // SAUVEGARDE
  // ══════════════════════════════════════════════════════

  static Future<void> sauvegarder(EtatJeu etat) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_kPartie, jsonEncode({
      'nom_guilde':           etat.nomGuilde,
      'jour':                 etat.jour,
      'or':                   etat.or,
      'renommee':             etat.renommee,
      'combat_fait':          etat.combatDuJourFait,
      'fuite_interdite':      etat.fuiteInterdite,
      'zone_selectionnee':    etat.zoneSelectionneeId,
      'evenements_vus':       etat.evenementsVus.toList(),
      'choix_pris':           etat.choixPris,
      'jour_evenement_vu':    etat.jourEvenementVu,
      'chaines_en_cours':     etat.chainesEnCours,
      'sous_zones_completes': etat.souZonesCompletes.toList(),
      'derniere_zone':        etat.derniereZoneVaincue,
      'coffre':               etat.coffreGuilde.toJson(),
    }));

    await prefs.setString(_kMercs, jsonEncode(
        etat.mercenaires.map(_mercToJson).toList()));

    await prefs.setString(_kBats, jsonEncode(
        etat.batiments.map(_batToJson).toList()));

    await prefs.setString(_kEquipe, jsonEncode(
        etat.equipeDeCombaIds));
  }

  // ══════════════════════════════════════════════════════
  // CHARGEMENT
  // ══════════════════════════════════════════════════════

  static Future<EtatJeu?> charger(List<Classe> classes) async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_kPartie);
    if (raw == null) return null;

    try {
      final p = jsonDecode(raw) as Map<String, dynamic>;

      // v2 fields
      final evVus = Set<String>.from(
          (p['evenements_vus'] as List? ?? []).cast<String>());
      final choix = (p['choix_pris'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v as String));
      final joursVus = (p['jour_evenement_vu'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, (v as num).toInt()));
      final chaines = List<String>.from(
          (p['chaines_en_cours'] as List? ?? []).cast<String>());
      final szCompletes = Set<String>.from(
          (p['sous_zones_completes'] as List? ?? []).cast<String>());

      // Coffre
      final coffreJson = p['coffre'] as Map<String, dynamic>?;
      final coffre = _coffreFromJson(coffreJson);

      // Mercenaires
      final mercsRaw = prefs.getString(_kMercs);
      final mercs = mercsRaw != null
          ? (jsonDecode(mercsRaw) as List)
              .map((m) => _mercFromJson(m, classes))
              .whereType<Mercenaire>().toList()
          : <Mercenaire>[];

      // Bâtiments
      final batsRaw = prefs.getString(_kBats);
      final bats = batsRaw != null
          ? (jsonDecode(batsRaw) as List)
              .map((b) => _batFromJson(b))
              .whereType<Batiment>().toList()
          : _batimentsDefaut();

      // Équipe
      final eqRaw  = prefs.getString(_kEquipe);
      final equipe = eqRaw != null
          ? List<String>.from(jsonDecode(eqRaw) as List)
          : <String>[];

      return EtatJeu(
        nomGuilde:           p['nom_guilde'] as String,
        jour:               (p['jour']      as num).toInt(),
        or:                 (p['or']        as num).toInt(),
        renommee:           (p['renommee']  as num).toInt(),
        combatDuJourFait:    p['combat_fait']     as bool? ?? false,
        fuiteInterdite:      p['fuite_interdite']  as bool? ?? false,
        zoneSelectionneeId:  p['zone_selectionnee'] as String?,
        mercenaires:         mercs,
        batiments:           bats,
        zones:               [],
        equipeDeCombaIds:    equipe,
        evenementsVus:       evVus,
        choixPris:           choix,
        jourEvenementVu:     joursVus,
        chainesEnCours:      chaines,
        souZonesCompletes:   szCompletes,
        derniereZoneVaincue: p['derniere_zone'] as String?,
        coffreGuilde:        coffre,
      );
    } catch (e) {
      print('GameDatabase.charger erreur: $e');
      return null;
    }
  }

  static Future<bool> partieExiste() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_kPartie);
  }

  static Future<void> supprimerPartie() async => supprimer();

  static Future<void> supprimer() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_kPartie),
      prefs.remove(_kMercs),
      prefs.remove(_kBats),
      prefs.remove(_kEquipe),
    ]);
  }

  // ══════════════════════════════════════════════════════
  // SÉRIALISATION MERCENAIRE
  // ══════════════════════════════════════════════════════

  static Map<String, dynamic> _mercToJson(Mercenaire m) => {
    'id':           m.id,
    'nom':          m.nom,
    'classe_id':    m.classeActuelle.id,
    'niveau':       m.niveau,
    'xp':           m.xp,
    'hp':           m.hp,
    'stats':        m.stats.map((k, v) => MapEntry(k.name, v)),
    'substats':     m.substats.map((k, v) => MapEntry(k.name, v)),
    'statut':       m.statut.name,
    'poste_id':     m.posteAssigneId,
    'gravite':      m.gravite?.name,
    'jours_bless':  m.joursRestantsInfirmerie,
    'nb_blesse':    m.nombreFoisBlesse,
    'combats':      m.combatsGagnes,
    'pts_stat':     m.pointsStatDisponibles,
    'hist':         m.historiqueClasses.map((c) => c.id).toList(),
    'sorts':        m.sortsActifs.map((s) => s.id).toList(),
  };

  static Mercenaire? _mercFromJson(dynamic raw, List<Classe> classes) {
    try {
      final j       = raw as Map<String, dynamic>;
      final classId = j['classe_id'] as String;
      final classe  = classes.firstWhere(
          (c) => c.id == classId, orElse: () => classes.first);

      final stats = (j['stats'] as Map<String, dynamic>? ?? {}).map((k, v) {
        final s = StatPrincipale.values
            .firstWhere((e) => e.name == k, orElse: () => StatPrincipale.FOR);
        return MapEntry(s, (v as num).toInt());
      });

      final subs = (j['substats'] as Map<String, dynamic>? ?? {}).map((k, v) {
        final s = Substat.values
            .firstWhere((e) => e.name == k, orElse: () => Substat.nature);
        return MapEntry(s, (v as num).toInt());
      });

      final statut = MercenaireSatut.values.firstWhere(
          (s) => s.name == j['statut'], orElse: () => MercenaireSatut.libre);

      final gravite = j['gravite'] != null
          ? GraviteBlessure.values.firstWhere(
              (g) => g.name == j['gravite'],
              orElse: () => GraviteBlessure.legere)
          : null;

      final hist = (j['hist'] as List? ?? [])
          .map((id) => classes.firstWhere(
              (c) => c.id == id, orElse: () => classe))
          .toList();

      return Mercenaire(
        id:                      j['id']  as String,
        nom:                     j['nom'] as String,
        classeActuelle:          classe,
        niveau:                 (j['niveau']   as num).toInt(),
        xp:                     (j['xp']       as num).toInt(),
        hp:                     (j['hp']       as num).toInt(),
        stats:                   stats,
        substats:                subs,
        statut:                  statut,
        posteAssigneId:          j['poste_id'] as String?,
        gravite:                 gravite,
        joursRestantsInfirmerie:(j['jours_bless'] as num?)?.toInt() ?? 0,
        nombreFoisBlesse:       (j['nb_blesse']   as num?)?.toInt() ?? 0,
        combatsGagnes:          (j['combats']     as num?)?.toInt() ?? 0,
        pointsStatDisponibles:  (j['pts_stat']    as num?)?.toInt() ?? 0,
        historiqueClasses:       hist,
      );
    } catch (e) {
      print('_mercFromJson erreur: $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════════════
  // SÉRIALISATION BÂTIMENT
  // ══════════════════════════════════════════════════════

  static Map<String, dynamic> _batToJson(Batiment b) => {
    'id':        b.id,
    'type':      b.type.name,
    'niveau':    b.niveau,
    'etat':      b.etat.name,
    'decouvert': b.estDecouvert,
    'mercs':     b.mercsAssignesIds,
  };

  static Batiment? _batFromJson(dynamic raw) {
    try {
      final j    = raw as Map<String, dynamic>;
      final type = BatimentType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => BatimentType.bureauDeRecrutement);
      final etat = BatimentEtat.values.firstWhere(
          (e) => e.name == j['etat'],
          orElse: () => BatimentEtat.intact);
      return Batiment(
        id:              j['id']   as String,
        type:            type,
        niveau:         (j['niveau'] as num).toInt(),
        etat:            etat,
        estDecouvert:    j['decouvert'] as bool? ?? false,
        mercsAssignesIds: List<String>.from(j['mercs'] as List? ?? []),
      );
    } catch (e) {
      print('_batFromJson erreur: $e');
      return null;
    }
  }

  // ── Coffre depuis JSON ──
  static CoffreGuilde _coffreFromJson(Map<String, dynamic>? json) {
    final coffre = CoffreGuilde();
    // Le coffre sera rechargé depuis les objets disponibles
    // On stocke juste les quantités — les objets sont rechargés au runtime
    return coffre;
  }

  // ── Bâtiments par défaut ──
  static List<Batiment> _batimentsDefaut() => [
    Batiment(id: 'bureau',    type: BatimentType.bureauDeRecrutement,
        niveau: 1, etat: BatimentEtat.intact,    estDecouvert: true),
    Batiment(id: 'dortoir',   type: BatimentType.dortoir,
        niveau: 0, etat: BatimentEtat.detruit,   estDecouvert: false),
    Batiment(id: 'cuisine',   type: BatimentType.cuisine,
        niveau: 0, etat: BatimentEtat.detruit,   estDecouvert: false),
    Batiment(id: 'forge',     type: BatimentType.forge,
        niveau: 0, etat: BatimentEtat.detruit,   estDecouvert: false),
    Batiment(id: 'infirmerie',type: BatimentType.infirmerie,
        niveau: 0, etat: BatimentEtat.detruit,   estDecouvert: false),
    Batiment(id: 'bibliotheque',type: BatimentType.bibliotheque,
        niveau: 0, etat: BatimentEtat.detruit,   estDecouvert: false),
    Batiment(id: 'taverne',   type: BatimentType.taverne,
        niveau: 0, etat: BatimentEtat.endommage, estDecouvert: false),
    Batiment(id: 'tourDeGarde',type: BatimentType.tourDeGarde,
        niveau: 0, etat: BatimentEtat.detruit,   estDecouvert: false),
    Batiment(id: 'terrainEntrainement',type: BatimentType.terrainEntrainement,
        niveau: 0, etat: BatimentEtat.detruit,   estDecouvert: false),
    Batiment(id: 'siteDeRituel',type: BatimentType.siteDeRituel,
        niveau: 0, etat: BatimentEtat.detruit,   estDecouvert: false),
    Batiment(id: 'temple',    type: BatimentType.temple,
        niveau: 0, etat: BatimentEtat.detruit,   estDecouvert: false),
    Batiment(id: 'lac',       type: BatimentType.lac,
        niveau: 0, etat: BatimentEtat.endommage, estDecouvert: false),
    Batiment(id: 'repaireDesOmbres',type: BatimentType.repaireDesOmbres,
        niveau: 0, etat: BatimentEtat.detruit,   estDecouvert: false),
    Batiment(id: 'boutique',  type: BatimentType.boutique,
        niveau: 0, etat: BatimentEtat.detruit,   estDecouvert: false),
  ];
}
