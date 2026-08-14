import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/channel.dart';
import '../../models/profile.dart';
import '../../providers/content_provider.dart';
import 'vod_list_screen.dart';

/// Filme (VOD): zeigt die Kategorien. Nur fuer Xtream-Profile verfuegbar,
/// da M3U-Playlists keine getrennte VOD-Struktur liefern.
class VodScreen extends ConsumerWidget {
  final Profile profile;
  const VodScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (profile: profile, type: StreamType.vod);
    final categoriesAsync = ref.watch(categoriesProvider(query));

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text(err.toString().replaceFirst('Exception: ', '')),
      ),
      data: (categories) {
        if (categories.isEmpty) {
          return const Center(child: Text('Keine Film-Kategorien gefunden.'));
        }
        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, i) {
            final category = categories[i];
            return ListTile(
              leading: const Icon(Icons.movie_outlined),
              title: Text(category.name),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VodListScreen(profile: profile, category: category),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
