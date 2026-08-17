import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/channel.dart';
import '../../models/profile.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/channel_actions_menu.dart';
import '../../widgets/favorite_button.dart';
import '../live_tv/player_screen.dart';
import '../series/series_detail_screen.dart';

/// Liste aller favorisierten Sender/Filme/Serien des aktiven Profils.
class FavoritesScreen extends ConsumerWidget {
  final Profile profile;
  const FavoritesScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider(profile.id));

    if (favorites.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text('Noch keine Favoriten. Tippe auf das Herz-Symbol bei einem\nSender, Film oder einer Serie, um sie hier zu sammeln.',
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: favorites.length,
      itemBuilder: (context, i) {
        final channel = favorites[i];
        return ListTile(
          leading: _Logo(channel: channel),
          title: Text(channel.name),
          subtitle: Text(_typeLabel(channel.streamType)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FavoriteButton(profileId: profile.id, channel: channel),
              ChannelActionsMenu(profileId: profile.id, channel: channel),
            ],
          ),
          onTap: () async {
            final allowed = await requestChannelUnlockIfNeeded(context, ref, profile.id, channel);
            if (!allowed || !context.mounted) return;
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

  String _typeLabel(StreamType type) => switch (type) {
        StreamType.live => 'Live TV',
        StreamType.vod => 'Film',
        StreamType.series => 'Serie',
      };
}

class _Logo extends StatelessWidget {
  final Channel channel;
  const _Logo({required this.channel});

  @override
  Widget build(BuildContext context) {
    final logo = channel.logoUrl;
    if (logo == null || logo.isEmpty) {
      return const CircleAvatar(child: Icon(Icons.live_tv));
    }
    return CircleAvatar(
      backgroundColor: Colors.transparent,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: logo,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => const Icon(Icons.live_tv),
          placeholder: (context, url) => const Icon(Icons.live_tv),
        ),
      ),
    );
  }
}
