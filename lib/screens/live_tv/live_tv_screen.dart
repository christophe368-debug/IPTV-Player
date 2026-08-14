import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/channel.dart';
import '../../models/profile.dart';
import '../../providers/content_provider.dart';
import 'channel_list_screen.dart';

/// Zeigt die Live-TV-Kategorien (z.B. "Sport", "Nachrichten") des aktiven
/// Profils. Tippen auf eine Kategorie oeffnet die zugehoerige Senderliste.
class LiveTvScreen extends ConsumerWidget {
  final Profile profile;
  const LiveTvScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (profile: profile, type: StreamType.live);
    final categoriesAsync = ref.watch(categoriesProvider(query));

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorView(
        message: err.toString().replaceFirst('Exception: ', ''),
        onRetry: () => ref.invalidate(categoriesProvider(query)),
      ),
      data: (categories) {
        if (categories.isEmpty) {
          return const Center(child: Text('Keine Kategorien gefunden.'));
        }
        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, i) {
            final category = categories[i];
            return ListTile(
              leading: const Icon(Icons.live_tv),
              title: Text(category.name),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChannelListScreen(profile: profile, category: category),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Erneut versuchen')),
          ],
        ),
      ),
    );
  }
}
