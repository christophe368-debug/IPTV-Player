import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/category.dart';
import '../../models/channel.dart';
import '../../models/profile.dart';
import '../../providers/content_provider.dart';
import '../../widgets/channel_actions_menu.dart';
import '../../widgets/poster_grid.dart';
import 'series_detail_screen.dart';

class SeriesListScreen extends ConsumerWidget {
  final Profile profile;
  final Category category;
  const SeriesListScreen({super.key, required this.profile, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (profile: profile, type: StreamType.series, categoryId: category.id);
    final seriesAsync = ref.watch(channelsProvider(query));

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: seriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString().replaceFirst('Exception: ', ''))),
        data: (series) {
          if (series.isEmpty) {
            return const Center(child: Text('Keine Serien in dieser Kategorie.'));
          }
          return PosterGrid(
            items: series,
            onTap: (show) async {
              final allowed = await requestChannelUnlockIfNeeded(context, ref, profile.id, show);
              if (!allowed || !context.mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SeriesDetailScreen(profile: profile, show: show)),
              );
            },
          );
        },
      ),
    );
  }
}
