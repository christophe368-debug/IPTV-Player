import 'package:hive_flutter/hive_flutter.dart';
import '../models/profile.dart';

/// Kuemmert sich um die lokale Speicherung (Hive-Datenbank) auf dem Geraet:
/// Profile (IPTV-Zugaenge), Favoriten, und spaeter Cache-Daten.
/// Hive speichert Daten als einfache Maps - keine Code-Generierung noetig.
class StorageService {
  static const _profilesBoxName = 'profiles';
  static const _favoritesBoxName = 'favorites';
  static const _settingsBoxName = 'settings';

  late Box _profilesBox;
  late Box _favoritesBox;
  late Box _settingsBox;

  /// Muss einmal beim App-Start aufgerufen werden (siehe main.dart).
  Future<void> init() async {
    await Hive.initFlutter();
    _profilesBox = await Hive.openBox(_profilesBoxName);
    _favoritesBox = await Hive.openBox(_favoritesBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  // --- Profile ---

  List<Profile> getProfiles() {
    return _profilesBox.values
        .map((e) => Profile.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveProfile(Profile profile) async {
    await _profilesBox.put(profile.id, profile.toMap());
  }

  Future<void> deleteProfile(String id) async {
    await _profilesBox.delete(id);
  }

  // --- Aktives Profil (zuletzt genutztes) ---

  String? getActiveProfileId() => _settingsBox.get('activeProfileId') as String?;

  Future<void> setActiveProfileId(String id) async {
    await _settingsBox.put('activeProfileId', id);
  }

  // --- Favoriten: Set von Channel-IDs pro Profil ---

  List<String> getFavoriteIds(String profileId) {
    final raw = _favoritesBox.get(profileId);
    if (raw == null) return [];
    return List<String>.from(raw as List);
  }

  Future<void> toggleFavorite(String profileId, String channelId) async {
    final current = getFavoriteIds(profileId);
    if (current.contains(channelId)) {
      current.remove(channelId);
    } else {
      current.add(channelId);
    }
    await _favoritesBox.put(profileId, current);
  }
}
