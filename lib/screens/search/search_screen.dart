import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/channel.dart';
import '../../models/profile.dart';
import '../../providers/content_provider.dart';
import '../live_tv/player_screen.dart';
import '../series/series_detail_screen.dart';

/// Durchsucht Live-TV (und bei Xtream-Profilen auch Filme/Serien) nach
/// Sendername. Laedt die vollstaendigen Listen erst, sobald tatsaechlich
/// etwas eingegeben wurde - nicht schon beim Oeffnen des Tabs.
class SearchScreen extends ConsumerStatefulWidget {
  final Profile profile;
  const SearchScreen({super.key, required this.profile});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _controller,
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Sender, Film oder Serie suchen...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
        ),
        Expanded(
          child: _query.isEmpty
              ? const Center(child: Text('Suchbegriff eingeben, um zu starten.'))
              : _SearchResults(profile: widget.profile, query: _query),
        ),
      ],
    );
  }
}

class _SearchResults extends ConsumerWidget {
  final Profile profile;
  final String query;
  const _SearchResults({required this.profile, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isXtream = profile.type == ProfileType.xtream;
    final liveAsync = ref.watch(channelsProvider((profile: profile, type: StreamType.live, categoryId: null)));
    final vodAsync = isXtream
        ? ref.watch(channelsProvider((profile: profile, type: StreamType.vod, categoryId: null)))
        : const AsyncValue.data(<Channel>[]);
    final seriesAsync = isXtream
        ? ref.watch(channelsProvider((profile: profile, type: StreamType.series, categoryId: null)))
        : const AsyncValue.data(<Channel>[]);

    final isLoading = liveAsync.isLoading || vodAsync.isLoading || seriesAsync.isLoading;
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final lowerQuery = query.toLowerCase();
    final results = <Channel>[
      ...liveAsync.valueOrNull ?? [],
      ...vodAsync.valueOrNull ?? [],
      ...seriesAsync.valueOrNull ?? [],
    ].where((c) => c.name.toLowerCase().contains(lowerQuery)).toList();

    if (results.isEmpty) {
      return const Center(child: Text('Keine Treffer.'));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, i) {
        final channel = results[i];
        return ListTile(
          leading: Icon(_iconFor(channel.streamType)),
          title: Text(channel.name),
          subtitle: Text(_typeLabel(channel.streamType)),
          onTap: () {
            if (channel.streamType == StreamType.series) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SeriesDetailScreen(profile: profile, show: channel)),
              );
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlayerScreen(title: channel.name, streamUrl: channel.streamUrl),
                ),
              );
            }
          },
        );
      },
    );
  }

  IconData _iconFor(StreamType type) => switch (type) {
        StreamType.live => Icons.live_tv,
        StreamType.vod => Icons.movie_outlined,
        StreamType.series => Icons.tv_outlined,
      };

  String _typeLabel(StreamType type) => switch (type) {
        StreamType.live => 'Live TV',
        StreamType.vod => 'Film',
        StreamType.series => 'Serie',
      };
}
