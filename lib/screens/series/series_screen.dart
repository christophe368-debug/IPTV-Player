import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/channel.dart';
import '../../models/profile.dart';
import '../../providers/content_provider.dart';
import 'series_list_screen.dart';

/// Serien: zeigt die Kategorien. Nur fuer Xtream-Profile verfuegbar.
class SeriesScreen extends ConsumerWidget {
  final Profile profile;
  const SeriesScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (profile: profile, type: StreamType.series);
    final categoriesAsync = ref.watch(categoriesProvider(query));

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text(err.toString().replaceFirst('Exception: ', '')),
      ),
      data: (categories) {
        if (categories.isEmpty) {
          return const Center(child: Text('Keine Serien-Kategorien gefunden.'));
        }
        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, i) {
            final category = categories[i];
            return ListTile(
              leading: const Icon(Icons.tv_outlined),
              title: Text(category.name),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SeriesListScreen(profile: profile, category: category),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
