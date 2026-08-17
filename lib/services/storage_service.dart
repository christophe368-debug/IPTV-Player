import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/channel.dart';
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
  ///
  /// [testDirectoryPath] wird nur in Tests gebraucht: Hive.initFlutter()
  /// fragt intern per Plattform-Kanal (path_provider) nach dem
  /// App-Verzeichnis, was in `flutter test` nicht beantwortet wird und die
  /// Tests unbegrenzt haengen laesst. Mit einem direkt uebergebenen
  /// Verzeichnis (z.B. ein Temp-Ordner) wird dieser Kanal umgangen.
  Future<void> init({String? testDirectoryPath}) async {
    if (testDirectoryPath != null) {
      Hive.init(testDirectoryPath);
    } else {
      await Hive.initFlutter();
    }
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

  // --- Favoriten: vollstaendige Channel-Objekte pro Profil ---
  // (nicht nur IDs, damit die Favoriten-Liste ohne erneutes Nachladen vom
  // Server angezeigt werden kann)

  List<Channel> getFavorites(String profileId) {
    final raw = _favoritesBox.get(profileId) as List<dynamic>?;
    if (raw == null) return [];
    return raw.map((e) => Channel.fromMap(Map<dynamic, dynamic>.from(e as Map))).toList();
  }

  bool isFavorite(String profileId, Channel channel) {
    return getFavorites(profileId).any((c) => c.favoriteKey == channel.favoriteKey);
  }

  Future<void> toggleFavorite(String profileId, Channel channel) async {
    final current = getFavorites(profileId);
    final exists = current.any((c) => c.favoriteKey == channel.favoriteKey);
    if (exists) {
      current.removeWhere((c) => c.favoriteKey == channel.favoriteKey);
    } else {
      current.add(channel);
    }
    await _favoritesBox.put(profileId, current.map((c) => c.toMap()).toList());
  }

  // --- Darstellung ---

  /// 'system', 'light' oder 'dark'.
  String getThemeMode() => (_settingsBox.get('themeMode') as String?) ?? 'system';

  Future<void> setThemeMode(String mode) async {
    await _settingsBox.put('themeMode', mode);
  }

  // --- Eltern-PIN (Kindersicherung) ---

  bool get hasParentalPin => _settingsBox.get('parentalPinHash') != null;

  Future<void> setParentalPin(String pin) async {
    await _settingsBox.put('parentalPinHash', _hashPin(pin));
  }

  Future<void> clearParentalPin() async {
    await _settingsBox.delete('parentalPinHash');
  }

  bool checkParentalPin(String pin) {
    final stored = _settingsBox.get('parentalPinHash') as String?;
    if (stored == null) return false;
    return stored == _hashPin(pin);
  }

  String _hashPin(String pin) => sha256.convert(utf8.encode(pin)).toString();

  // --- Gesperrte Kategorien pro Profil (Kindersicherung) ---

  Set<String> getLockedCategoryKeys(String profileId) {
    final raw = _settingsBox.get('lockedCategories_$profileId') as List<dynamic>?;
    if (raw == null) return {};
    return raw.map((e) => e.toString()).toSet();
  }

  Future<void> toggleCategoryLock(String profileId, String categoryKey) async {
    final current = getLockedCategoryKeys(profileId);
    if (current.contains(categoryKey)) {
      current.remove(categoryKey);
    } else {
      current.add(categoryKey);
    }
    await _settingsBox.put('lockedCategories_$profileId', current.toList());
  }

  // --- Ausgeblendete Kategorien pro Profil ---
  // (unabhaengig von der Kindersicherung - einfach "brauche ich nicht",
  // keine PIN noetig)

  Set<String> getHiddenCategoryKeys(String profileId) {
    final raw = _settingsBox.get('hiddenCategories_$profileId') as List<dynamic>?;
    if (raw == null) return {};
    return raw.map((e) => e.toString()).toSet();
  }

  Future<void> toggleCategoryHidden(String profileId, String categoryKey) async {
    final current = getHiddenCategoryKeys(profileId);
    if (current.contains(categoryKey)) {
      current.remove(categoryKey);
    } else {
      current.add(categoryKey);
    }
    await _settingsBox.put('hiddenCategories_$profileId', current.toList());
  }

  // --- Umbenannte Kategorien pro Profil ---

  Map<String, String> getCategoryNameOverrides(String profileId) {
    final raw = _settingsBox.get('categoryNames_$profileId') as Map<dynamic, dynamic>?;
    if (raw == null) return {};
    return raw.map((key, value) => MapEntry(key.toString(), value.toString()));
  }

  Future<void> setCategoryNameOverride(String profileId, String categoryKey, String? name) async {
    final current = getCategoryNameOverrides(profileId);
    if (name == null || name.trim().isEmpty) {
      current.remove(categoryKey);
    } else {
      current[categoryKey] = name.trim();
    }
    await _settingsBox.put('categoryNames_$profileId', current);
  }

  // --- Ausgeblendete/gesperrte einzelne Sender/Filme/Serien pro Profil ---
  // (nutzt Channel.favoriteKey, also z.B. "live_123" - eindeutig auch
  // ueber verschiedene Inhaltstypen hinweg)

  Set<String> getHiddenChannelKeys(String profileId) => _getKeySet('hiddenChannels_$profileId');

  Future<void> toggleChannelHidden(String profileId, String channelKey) =>
      _toggleKeySet('hiddenChannels_$profileId', channelKey);

  Set<String> getLockedChannelKeys(String profileId) => _getKeySet('lockedChannels_$profileId');

  Future<void> toggleChannelLock(String profileId, String channelKey) =>
      _toggleKeySet('lockedChannels_$profileId', channelKey);

  Set<String> _getKeySet(String storageKey) {
    final raw = _settingsBox.get(storageKey) as List<dynamic>?;
    if (raw == null) return {};
    return raw.map((e) => e.toString()).toSet();
  }

  Future<void> _toggleKeySet(String storageKey, String key) async {
    final current = _getKeySet(storageKey);
    if (current.contains(key)) {
      current.remove(key);
    } else {
      current.add(key);
    }
    await _settingsBox.put(storageKey, current.toList());
  }
}
