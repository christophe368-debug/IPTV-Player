import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import 'profile_provider.dart';

/// Aktuell gewaehlter App-Theme-Modus (System/Hell/Dunkel), persistiert.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ThemeModeNotifier(storage);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final StorageService _storage;
  ThemeModeNotifier(this._storage) : super(_fromString(_storage.getThemeMode()));

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _storage.setThemeMode(mode.name);
  }

  static ThemeMode _fromString(String value) {
    return ThemeMode.values.firstWhere((m) => m.name == value, orElse: () => ThemeMode.system);
  }
}

/// Ob fuer dieses Profil bereits gesperrte Kategorien existieren (Kindersicherung).
final lockedCategoriesProvider =
    StateNotifierProvider.family<LockedCategoriesNotifier, Set<String>, String>((ref, profileId) {
  final storage = ref.watch(storageServiceProvider);
  return LockedCategoriesNotifier(storage, profileId);
});

class LockedCategoriesNotifier extends StateNotifier<Set<String>> {
  final StorageService _storage;
  final String _profileId;
  LockedCategoriesNotifier(this._storage, this._profileId)
      : super(_storage.getLockedCategoryKeys(_profileId));

  Future<void> toggle(String categoryKey) async {
    await _storage.toggleCategoryLock(_profileId, categoryKey);
    state = _storage.getLockedCategoryKeys(_profileId);
  }

  bool isLocked(String categoryKey) => state.contains(categoryKey);
}

/// Ob ueberhaupt eine Eltern-PIN eingerichtet ist.
final hasParentalPinProvider = Provider<bool>((ref) {
  return ref.watch(storageServiceProvider).hasParentalPin;
});

/// Vom Nutzer ausgeblendete Kategorien (kein PIN-Schutz, einfach "brauche
/// ich nicht in der Liste").
final hiddenCategoriesProvider =
    StateNotifierProvider.family<HiddenCategoriesNotifier, Set<String>, String>((ref, profileId) {
  final storage = ref.watch(storageServiceProvider);
  return HiddenCategoriesNotifier(storage, profileId);
});

class HiddenCategoriesNotifier extends StateNotifier<Set<String>> {
  final StorageService _storage;
  final String _profileId;
  HiddenCategoriesNotifier(this._storage, this._profileId)
      : super(_storage.getHiddenCategoryKeys(_profileId));

  Future<void> toggle(String categoryKey) async {
    await _storage.toggleCategoryHidden(_profileId, categoryKey);
    state = _storage.getHiddenCategoryKeys(_profileId);
  }
}

/// Vom Nutzer vergebene eigene Namen fuer Kategorien (categoryKey -> Name).
final categoryNameOverridesProvider =
    StateNotifierProvider.family<CategoryNameOverridesNotifier, Map<String, String>, String>((ref, profileId) {
  final storage = ref.watch(storageServiceProvider);
  return CategoryNameOverridesNotifier(storage, profileId);
});

class CategoryNameOverridesNotifier extends StateNotifier<Map<String, String>> {
  final StorageService _storage;
  final String _profileId;
  CategoryNameOverridesNotifier(this._storage, this._profileId)
      : super(_storage.getCategoryNameOverrides(_profileId));

  Future<void> setName(String categoryKey, String? name) async {
    await _storage.setCategoryNameOverride(_profileId, categoryKey, name);
    state = _storage.getCategoryNameOverrides(_profileId);
  }
}

/// Vom Nutzer ausgeblendete einzelne Sender/Filme/Serien (Channel.favoriteKey).
final hiddenChannelsProvider =
    StateNotifierProvider.family<HiddenChannelsNotifier, Set<String>, String>((ref, profileId) {
  final storage = ref.watch(storageServiceProvider);
  return HiddenChannelsNotifier(storage, profileId);
});

class HiddenChannelsNotifier extends StateNotifier<Set<String>> {
  final StorageService _storage;
  final String _profileId;
  HiddenChannelsNotifier(this._storage, this._profileId)
      : super(_storage.getHiddenChannelKeys(_profileId));

  Future<void> toggle(String channelKey) async {
    await _storage.toggleChannelHidden(_profileId, channelKey);
    state = _storage.getHiddenChannelKeys(_profileId);
  }
}

/// Einzeln gesperrte Sender/Filme/Serien (Channel.favoriteKey) -
/// Kindersicherung auf Inhalts-Ebene statt nur pro Kategorie.
final lockedChannelsProvider =
    StateNotifierProvider.family<LockedChannelsNotifier, Set<String>, String>((ref, profileId) {
  final storage = ref.watch(storageServiceProvider);
  return LockedChannelsNotifier(storage, profileId);
});

class LockedChannelsNotifier extends StateNotifier<Set<String>> {
  final StorageService _storage;
  final String _profileId;
  LockedChannelsNotifier(this._storage, this._profileId)
      : super(_storage.getLockedChannelKeys(_profileId));

  Future<void> toggle(String channelKey) async {
    await _storage.toggleChannelLock(_profileId, channelKey);
    state = _storage.getLockedChannelKeys(_profileId);
  }
}
