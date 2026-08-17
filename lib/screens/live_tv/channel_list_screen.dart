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
import 'epg_grid_screen.dart';
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
      appBar: AppBar(
        title: Text(widget.category.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view_outlined),
            tooltip: 'TV-Guide (Raster)',
            onPressed: channelsAsync.valueOrNull == null
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EpgGridScreen(
                          profile: widget.profile,
                          channels: channelsAsync.valueOrNull!,
                        ),
                      ),
                    ),
          ),
        ],
      ),
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
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: channels.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final channel = channels[i];
                    final isHidden = hiddenKeys.contains(channel.favoriteKey);
                    return TvFocusHighlight(
                      child: Card(
                        child: InkWell(
                          autofocus: i == 0,
                          borderRadius: BorderRadius.circular(14),
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
                                builder: (_) =>
                                    PlayerScreen(title: channel.name, streamUrl: channel.streamUrl),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                _ChannelLogo(channel: channel),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        channel.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: isHidden ? Colors.grey : null,
                                            ),
                                      ),
                                      if (isHidden)
                                        Text('Ausgeblendet', style: Theme.of(context).textTheme.bodySmall),
                                    ],
                                  ),
                                ),
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
                          ),
                        ),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 56,
        height: 56,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: logo != null && logo.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.all(6),
                child: CachedNetworkImage(
                  imageUrl: logo,
                  fit: BoxFit.contain,
                  errorWidget: (context, url, error) => const Icon(Icons.tv_outlined),
                  placeholder: (context, url) => const Icon(Icons.tv_outlined),
                ),
              )
            : const Icon(Icons.tv_outlined),
      ),
    );
  }
}
