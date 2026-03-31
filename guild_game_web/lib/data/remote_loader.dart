// lib/data/remote_loader.dart
// Version Web — pas de cache SQLite
// Les données sont chargées directement depuis les assets

import 'package:flutter/services.dart';

class RemoteLoader {
  static const baseUrl = '';

  static Future<String?> chargerDepuisCache(String cle) async {
    return null; // pas de cache sur web
  }

  static Future<void> sauvegarderDansCache(String cle, String data) async {
    // no-op sur web
  }

  static Future<String> chargerAsset(String chemin) async {
    return await rootBundle.loadString(chemin);
  }
}
