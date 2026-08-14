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
