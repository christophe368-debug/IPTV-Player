import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import '../services/storage_service.dart';

/// Einmalige Instanz des StorageService fuer die ganze App.
/// Wird in main.dart per `overrideWithValue` mit der initialisierten
/// Instanz befuellt (siehe main.dart).
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('storageServiceProvider muss in main.dart ueberschrieben werden');
});

/// Liste aller gespeicherten Profile (IPTV-Zugaenge) des Nutzers.
final profilesProvider = StateNotifierProvider<ProfilesNotifier, List<Profile>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ProfilesNotifier(storage);
});

class ProfilesNotifier extends StateNotifier<List<Profile>> {
  final StorageService _storage;
  ProfilesNotifier(this._storage) : super(_storage.getProfiles());

  Future<void> add(Profile profile) async {
    await _storage.saveProfile(profile);
    state = _storage.getProfiles();
  }

  Future<void> remove(String id) async {
    await _storage.deleteProfile(id);
    state = _storage.getProfiles();
  }
}

/// Das aktuell aktive Profil (mit dem der Nutzer gerade eingeloggt ist).
final activeProfileIdProvider = StateProvider<String?>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.getActiveProfileId();
});

final activeProfileProvider = Provider<Profile?>((ref) {
  final id = ref.watch(activeProfileIdProvider);
  final profiles = ref.watch(profilesProvider);
  if (id == null) return null;
  try {
    return profiles.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
});
