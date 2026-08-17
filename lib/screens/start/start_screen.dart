import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/channel.dart';
import '../../models/profile.dart';
import '../../providers/content_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/channel_actions_menu.dart';
import '../../widgets/live_pulse.dart';
import '../live_tv/channel_list_screen.dart';
import '../live_tv/player_screen.dart';
import '../series/series_detail_screen.dart';

/// Einstiegsbildschirm pro Profil: ein grosser Hero-Bereich fuer einen
/// Favoriten (oder eine Einladung, welche anzulegen) plus horizontal
/// scrollbare Reihen - Favoriten und ein Schnellzugriff auf Live-TV-
/// Kategorien. Ersetzt "man landet direkt in einer Liste" durch einen
/// Ueberblick, wie man ihn von Streaming-Apps kennt.
class StartScreen extends ConsumerWidget {
  final Profile profile;
  const StartScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider(profile.id));
    final categoriesAsync = ref.watch(categoriesProvider((profile: profile, type: StreamType.live)));

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _Hero(profile: profile, favorites: favorites),
        if (favorites.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SectionHeader('Favoriten'),
          SizedBox(
            height: 176,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: favorites.length,
              separatorBuilder: (context, i) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _PosterCard(profile: profile, channel: favorites[i]),
            ),
          ),
        ],
        const SizedBox(height: 24),
        _SectionHeader('Live-TV-Kategorien'),
        categoriesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(err.toString().replaceFirst('Exception: ', '')),
          ),
          data: (categories) {
            if (categories.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Keine Kategorien gefunden.'),
              );
            }
            return SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                separatorBuilder: (context, i) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final category = categories[i];
                  return ActionChip(
                    label: Text(category.name),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChannelListScreen(profile: profile, category: category),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _Hero extends ConsumerWidget {
  final Profile profile;
  final List<Channel> favorites;
  const _Hero({required this.profile, required this.favorites});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (favorites.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(24),
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Willkommen, ${profile.name}', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Favorisiere Sender, Filme oder Serien mit dem Herz-Symbol - sie erscheinen dann hier.'),
          ],
        ),
      );
    }

    // Immer der gleiche "zufaellige" Favorit pro Sitzung statt bei jedem
    // Rebuild neu gewuerfelt.
    final featured = favorites[Random(profile.id.hashCode).nextInt(favorites.length)];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (featured.logoUrl != null && featured.logoUrl!.isNotEmpty)
                CachedNetworkImage(imageUrl: featured.logoUrl!, fit: BoxFit.cover)
              else
                Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: 0.1), Colors.black.withValues(alpha: 0.85)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (featured.streamType == StreamType.live) const LiveBadge(),
                    const SizedBox(height: 8),
                    Text(
                      featured.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _open(context, ref, featured),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Abspielen'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref, Channel channel) async {
    final allowed = await requestChannelUnlockIfNeeded(context, ref, profile.id, channel);
    if (!allowed || !context.mounted) return;
    if (channel.streamType == StreamType.series) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SeriesDetailScreen(profile: profile, show: channel)),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PlayerScreen(title: channel.name, streamUrl: channel.streamUrl)),
      );
    }
  }
}

class _PosterCard extends ConsumerWidget {
  final Profile profile;
  final Channel channel;
  const _PosterCard({required this.profile, required this.channel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 120,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _open(context, ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    channel.logoUrl != null && channel.logoUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: channel.logoUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => _placeholder(context),
                          )
                        : _placeholder(context),
                    if (channel.streamType == StreamType.live)
                      const Positioned(top: 6, left: 6, child: LiveBadge()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              channel.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const Icon(Icons.live_tv, color: Colors.grey),
      );

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final allowed = await requestChannelUnlockIfNeeded(context, ref, profile.id, channel);
    if (!allowed || !context.mounted) return;
    if (channel.streamType == StreamType.series) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SeriesDetailScreen(profile: profile, show: channel)),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PlayerScreen(title: channel.name, streamUrl: channel.streamUrl)),
      );
    }
  }
}
