import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/category.dart';
import '../../models/channel.dart';
import '../../models/profile.dart';
import '../../providers/content_provider.dart';
import '../../widgets/favorite_button.dart';
import 'epg_screen.dart';
import 'player_screen.dart';

/// Zeigt alle Sender innerhalb einer Kategorie. Tippen auf einen Sender
/// startet die Wiedergabe im Player.
class ChannelListScreen extends ConsumerWidget {
  final Profile profile;
  final Category category;
  const ChannelListScreen({super.key, required this.profile, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (profile: profile, type: StreamType.live, categoryId: category.id);
    final channelsAsync = ref.watch(channelsProvider(query));

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: channelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(err.toString().replaceFirst('Exception: ', '')),
        ),
        data: (channels) {
          if (channels.isEmpty) {
            return const Center(child: Text('Keine Sender in dieser Kategorie.'));
          }
          return ListView.builder(
            itemCount: channels.length,
            itemBuilder: (context, i) {
              final channel = channels[i];
              return ListTile(
                leading: _ChannelLogo(channel: channel),
                title: Text(channel.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FavoriteButton(profileId: profile.id, channel: channel),
                    IconButton(
                      icon: const Icon(Icons.schedule),
                      tooltip: 'Programm anzeigen',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EpgScreen(profile: profile, channel: channel),
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PlayerScreen(title: channel.name, streamUrl: channel.streamUrl),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ChannelLogo extends StatelessWidget {
  final Channel channel;
  const _ChannelLogo({required this.channel});

  @override
  Widget build(BuildContext context) {
    final logo = channel.logoUrl;
    if (logo == null || logo.isEmpty) {
      return const CircleAvatar(child: Icon(Icons.tv));
    }
    return CircleAvatar(
      backgroundColor: Colors.transparent,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: logo,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => const Icon(Icons.tv),
          placeholder: (context, url) => const Icon(Icons.tv),
        ),
      ),
    );
  }
}
