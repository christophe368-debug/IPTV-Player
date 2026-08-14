import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/channel.dart';
import '../services/storage_service.dart';
import 'profile_provider.dart';

/// Favoritenliste des jeweils aktiven Profils.
final favoritesProvider =
    StateNotifierProvider.family<FavoritesNotifier, List<Channel>, String>((ref, profileId) {
  final storage = ref.watch(storageServiceProvider);
  return FavoritesNotifier(storage, profileId);
});

class FavoritesNotifier extends StateNotifier<List<Channel>> {
  final StorageService _storage;
  final String _profileId;

  FavoritesNotifier(this._storage, this._profileId) : super(_storage.getFavorites(_profileId));

  bool isFavorite(Channel channel) => state.any((c) => c.favoriteKey == channel.favoriteKey);

  Future<void> toggle(Channel channel) async {
    await _storage.toggleFavorite(_profileId, channel);
    state = _storage.getFavorites(_profileId);
  }
}
