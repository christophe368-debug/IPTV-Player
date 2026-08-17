import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/category.dart';
import '../../models/channel.dart';
import '../../models/profile.dart';
import '../../providers/content_provider.dart';
import '../../widgets/channel_actions_menu.dart';
import '../../widgets/poster_grid.dart';
import 'vod_detail_screen.dart';

class VodListScreen extends ConsumerWidget {
  final Profile profile;
  final Category category;
  const VodListScreen({super.key, required this.profile, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (profile: profile, type: StreamType.vod, categoryId: category.id);
    final moviesAsync = ref.watch(channelsProvider(query));

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: moviesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString().replaceFirst('Exception: ', ''))),
        data: (movies) {
          if (movies.isEmpty) {
            return const Center(child: Text('Keine Filme in dieser Kategorie.'));
          }
          return PosterGrid(
            items: movies,
            onTap: (movie) async {
              final allowed = await requestChannelUnlockIfNeeded(context, ref, profile.id, movie);
              if (!allowed || !context.mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => VodDetailScreen(profile: profile, movie: movie)),
              );
            },
          );
        },
      ),
    );
  }
}
