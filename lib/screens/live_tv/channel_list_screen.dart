import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/category.dart';
import '../../models/channel.dart';
import '../../models/profile.dart';
import '../../providers/content_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/channel_actions_menu.dart';
import '../../widgets/favorite_button.dart';
import '../../widgets/tv_focus_highlight.dart';
import 'epg_screen.dart';
import 'player_screen.dart';

/// Zeigt alle Sender innerhalb einer Kategorie. Tippen auf einen Sender
/// startet die Wiedergabe im Player (nach PIN-Abfrage, falls gesperrt).
class ChannelListScreen extends ConsumerStatefulWidget {
  final Profile profile;
  final Category category;
  const ChannelListScreen({super.key, required this.profile, required this.category});

  @override
  ConsumerState<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends ConsumerState<ChannelListScreen> {
  bool _showHidden = false;

  @override
  Widget build(BuildContext context) {
    final query = (profile: widget.profile, type: StreamType.live, categoryId: widget.category.id);
    final channelsAsync = ref.watch(channelsProvider(query));
    final hiddenKeys = ref.watch(hiddenChannelsProvider(widget.profile.id));

    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: channelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(err.toString().replaceFirst('Exception: ', '')),
        ),
        data: (allChannels) {
          if (allChannels.isEmpty) {
            return const Center(child: Text('Keine Sender in dieser Kategorie.'));
          }

          final channels = allChannels
              .where((c) => _showHidden || !hiddenKeys.contains(c.favoriteKey))
              .toList();

          return Column(
            children: [
              if (allChannels.any((c) => hiddenKeys.contains(c.favoriteKey)))
                SwitchListTile(
                  dense: true,
                  title: const Text('Ausgeblendete Sender anzeigen'),
                  value: _showHidden,
                  onChanged: (value) => setState(() => _showHidden = value),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: channels.length,
                  itemBuilder: (context, i) {
                    final channel = channels[i];
                    final isHidden = hiddenKeys.contains(channel.favoriteKey);
                    return TvFocusHighlight(
                      child: ListTile(
                        autofocus: i == 0,
                        leading: _ChannelLogo(channel: channel),
                        title: Text(
                          channel.name,
                          style: TextStyle(color: isHidden ? Colors.grey : null),
                        ),
                        subtitle: isHidden ? const Text('Ausgeblendet') : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FavoriteButton(profileId: widget.profile.id, channel: channel),
                            IconButton(
                              icon: const Icon(Icons.schedule),
                              tooltip: 'Programm anzeigen',
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => EpgScreen(profile: widget.profile, channel: channel),
                                ),
                              ),
                            ),
                            ChannelActionsMenu(profileId: widget.profile.id, channel: channel),
                          ],
                        ),
                        onTap: () async {
                          final allowed = await requestChannelUnlockIfNeeded(
                            context,
                            ref,
                            widget.profile.id,
                            channel,
                          );
                          if (!allowed || !context.mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PlayerScreen(title: channel.name, streamUrl: channel.streamUrl),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
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
