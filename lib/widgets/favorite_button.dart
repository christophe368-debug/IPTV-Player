import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/channel.dart';
import '../providers/favorites_provider.dart';

/// Herz-Icon zum Hinzufuegen/Entfernen eines Senders/Films/Episode zu den
/// Favoriten des aktiven Profils.
class FavoriteButton extends ConsumerWidget {
  final String profileId;
  final Channel channel;
  const FavoriteButton({super.key, required this.profileId, required this.channel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider(profileId));
    final isFavorite = favorites.any((c) => c.favoriteKey == channel.favoriteKey);

    return IconButton(
      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
      color: isFavorite ? Colors.redAccent : null,
      tooltip: isFavorite ? 'Aus Favoriten entfernen' : 'Zu Favoriten hinzufuegen',
      onPressed: () => ref.read(favoritesProvider(profileId).notifier).toggle(channel),
    );
  }
}
