import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/channel.dart';
import '../../models/profile.dart';
import '../../providers/content_provider.dart';
import '../../widgets/favorite_button.dart';
import '../live_tv/player_screen.dart';

class VodDetailScreen extends ConsumerWidget {
  final Profile profile;
  final Channel movie;
  const VodDetailScreen({super.key, required this.profile, required this.movie});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(vodDetailsProvider((profile: profile, vodId: movie.id)));

    return Scaffold(
      appBar: AppBar(
        title: Text(movie.name),
        actions: [FavoriteButton(profileId: profile.id, channel: movie)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: movie.logoUrl != null && movie.logoUrl!.isNotEmpty
                  ? CachedNetworkImage(imageUrl: movie.logoUrl!, height: 260, fit: BoxFit.cover)
                  : Container(
                      height: 260,
                      width: 180,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.movie_outlined, size: 48),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlayerScreen(title: movie.name, streamUrl: movie.streamUrl),
              ),
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Abspielen'),
          ),
          const SizedBox(height: 20),
          detailsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text(
              'Details konnten nicht geladen werden: ${err.toString().replaceFirst('Exception: ', '')}',
            ),
            data: (details) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (details.rating != null && details.rating!.isNotEmpty)
                  _InfoRow(label: 'Bewertung', value: details.rating!),
                if (details.releaseDate != null && details.releaseDate!.isNotEmpty)
                  _InfoRow(label: 'Erschienen', value: details.releaseDate!),
                if (details.genre != null && details.genre!.isNotEmpty)
                  _InfoRow(label: 'Genre', value: details.genre!),
                if (details.director != null && details.director!.isNotEmpty)
                  _InfoRow(label: 'Regie', value: details.director!),
                if (details.cast != null && details.cast!.isNotEmpty)
                  _InfoRow(label: 'Besetzung', value: details.cast!),
                if (details.plot != null && details.plot!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(details.plot!, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
