import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/channel.dart';
import '../../models/episode.dart';
import '../../models/profile.dart';
import '../../providers/content_provider.dart';
import '../../widgets/favorite_button.dart';
import '../live_tv/player_screen.dart';

class SeriesDetailScreen extends ConsumerStatefulWidget {
  final Profile profile;
  final Channel show;
  const SeriesDetailScreen({super.key, required this.profile, required this.show});

  @override
  ConsumerState<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends ConsumerState<SeriesDetailScreen> {
  int? _selectedSeason;

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(
      seriesDetailsProvider((profile: widget.profile, seriesId: widget.show.id)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.show.name),
        actions: [FavoriteButton(profileId: widget.profile.id, channel: widget.show)],
      ),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Details konnten nicht geladen werden: ${err.toString().replaceFirst('Exception: ', '')}'),
        ),
        data: (data) {
          final seasons = data.seasons.keys.toList()..sort();
          if (seasons.isEmpty) {
            return const Center(child: Text('Keine Staffeln/Episoden gefunden.'));
          }
          _selectedSeason ??= seasons.first;
          final episodes = data.seasons[_selectedSeason] ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.show.logoUrl != null && widget.show.logoUrl!.isNotEmpty
                        ? CachedNetworkImage(imageUrl: widget.show.logoUrl!, width: 100, height: 150, fit: BoxFit.cover)
                        : Container(
                            width: 100,
                            height: 150,
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.tv_outlined),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data.details.rating != null && data.details.rating!.isNotEmpty)
                          Text('Bewertung: ${data.details.rating}'),
                        if (data.details.genre != null && data.details.genre!.isNotEmpty)
                          Text('Genre: ${data.details.genre}'),
                        if (data.details.plot != null && data.details.plot!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(data.details.plot!, maxLines: 6, overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              DropdownButton<int>(
                value: _selectedSeason,
                items: seasons
                    .map((s) => DropdownMenuItem(value: s, child: Text('Staffel $s')))
                    .toList(),
                onChanged: (value) => setState(() => _selectedSeason = value),
              ),
              const SizedBox(height: 8),
              ...episodes.map((episode) => _EpisodeTile(episode: episode)),
            ],
          );
        },
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final Episode episode;
  const _EpisodeTile({required this.episode});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text('${episode.episodeNumber}')),
        title: Text(episode.title),
        trailing: const Icon(Icons.play_arrow),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlayerScreen(title: episode.title, streamUrl: episode.streamUrl),
          ),
        ),
      ),
    );
  }
}
