import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/channel.dart';
import '../../models/epg_program.dart';
import '../../models/profile.dart';
import '../../providers/content_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/channel_actions_menu.dart';
import 'player_screen.dart';

const double _channelColumnWidth = 140;
const double _pixelsPerMinute = 4;
const int _windowHours = 4;

/// TV-Guide-Raster: alle Sender einer Kategorie untereinander, Zeitleiste
/// quer, aktuelle Sendung farblich hervorgehoben. Klassische
/// Programmzeitschrift-Ansicht statt "ein Sender nach dem anderen
/// antippen" wie im normalen EPG-Screen.
class EpgGridScreen extends ConsumerStatefulWidget {
  final Profile profile;
  final List<Channel> channels;
  const EpgGridScreen({super.key, required this.profile, required this.channels});

  @override
  ConsumerState<EpgGridScreen> createState() => _EpgGridScreenState();
}

class _EpgGridScreenState extends ConsumerState<EpgGridScreen> {
  final _timeScrollController = ScrollController();
  late final DateTime _windowStart;
  late final DateTime _windowEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _windowStart = DateTime(now.year, now.month, now.day, now.hour);
    _windowEnd = _windowStart.add(const Duration(hours: _windowHours));

    // Nach dem ersten Frame ein Stueck zur aktuellen Uhrzeit scrollen,
    // statt immer ganz links (vor einer Stunde) zu starten.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final offset = now.difference(_windowStart).inMinutes * _pixelsPerMinute - 40;
      if (offset > 0 && _timeScrollController.hasClients) {
        _timeScrollController.jumpTo(offset);
      }
    });
  }

  @override
  void dispose() {
    _timeScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final epgAsync = ref.watch(gridEpgProvider((profile: widget.profile, channels: widget.channels)));
    final totalWidth = _windowEnd.difference(_windowStart).inMinutes * _pixelsPerMinute;

    return Scaffold(
      appBar: AppBar(title: const Text('TV-Guide')),
      body: epgAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(err.toString().replaceFirst('Exception: ', ''), textAlign: TextAlign.center),
          ),
        ),
        data: (epgByChannel) {
          if (epgByChannel.values.every((programs) => programs.isEmpty)) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Kein Programmfuehrer fuer diese Sender verfuegbar.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Column(
            children: [
              // Kopfzeile: Ecke + Zeitleiste (teilt sich den horizontalen
              // Scroll-Controller mit jeder einzelnen Sender-Zeile darunter,
              // damit alles synchron scrollt).
              Row(
                children: [
                  const SizedBox(width: _channelColumnWidth),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _timeScrollController,
                      scrollDirection: Axis.horizontal,
                      child: _TimeHeader(windowStart: _windowStart, totalWidth: totalWidth),
                    ),
                  ),
                ],
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: widget.channels.length,
                  separatorBuilder: (context, i) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final channel = widget.channels[i];
                    final programs = epgByChannel[channel.favoriteKey] ?? [];
                    return SizedBox(
                      height: 68,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: _channelColumnWidth, child: _ChannelCell(channel: channel)),
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _timeScrollController,
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: totalWidth,
                                child: _ChannelTimeline(
                                  profile: widget.profile,
                                  channel: channel,
                                  programs: programs,
                                  windowStart: _windowStart,
                                  windowEnd: _windowEnd,
                                  totalWidth: totalWidth,
                                ),
                              ),
                            ),
                          ),
                        ],
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

class _TimeHeader extends StatelessWidget {
  final DateTime windowStart;
  final double totalWidth;
  const _TimeHeader({required this.windowStart, required this.totalWidth});

  @override
  Widget build(BuildContext context) {
    final hourWidth = 60 * _pixelsPerMinute;
    final hours = totalWidth ~/ hourWidth;
    return SizedBox(
      width: totalWidth,
      height: 32,
      child: Stack(
        children: [
          for (var h = 0; h <= hours; h++)
            Positioned(
              left: h * hourWidth,
              top: 0,
              bottom: 0,
              child: Container(
                width: 1,
                color: Theme.of(context).dividerColor,
              ),
            ),
          for (var h = 0; h < hours; h++)
            Positioned(
              left: h * hourWidth + 6,
              top: 6,
              child: Text(
                _formatTime(windowStart.add(Duration(hours: h))),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _ChannelCell extends StatelessWidget {
  final Channel channel;
  const _ChannelCell({required this.channel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 36,
              height: 36,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: channel.logoUrl != null && channel.logoUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: channel.logoUrl!,
                      fit: BoxFit.contain,
                      errorWidget: (context, url, error) => const Icon(Icons.tv_outlined, size: 18),
                    )
                  : const Icon(Icons.tv_outlined, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              channel.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelTimeline extends ConsumerWidget {
  final Profile profile;
  final Channel channel;
  final List<EpgProgram> programs;
  final DateTime windowStart;
  final DateTime windowEnd;
  final double totalWidth;

  const _ChannelTimeline({
    required this.profile,
    required this.channel,
    required this.programs,
    required this.windowStart,
    required this.windowEnd,
    required this.totalWidth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (programs.isEmpty) {
      return Center(
        child: Text('Keine Daten', style: Theme.of(context).textTheme.bodySmall),
      );
    }

    final visible = programs.where((p) => p.end.isAfter(windowStart) && p.start.isBefore(windowEnd));

    return Stack(
      children: [
        for (final program in visible)
          Positioned(
            left: _offsetFor(program.start),
            width: _offsetFor(program.end) - _offsetFor(program.start),
            top: 4,
            bottom: 4,
            child: _ProgramBlock(
              program: program,
              onTap: () async {
                if (program.isCurrentlyRunning) {
                  final allowed = await requestChannelUnlockIfNeeded(context, ref, profile.id, channel);
                  if (!allowed || !context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlayerScreen(title: channel.name, streamUrl: channel.streamUrl),
                    ),
                  );
                }
              },
            ),
          ),
      ],
    );
  }

  double _offsetFor(DateTime time) {
    final clamped = time.isBefore(windowStart)
        ? windowStart
        : (time.isAfter(windowEnd) ? windowEnd : time);
    return clamped.difference(windowStart).inMinutes * _pixelsPerMinute;
  }
}

class _ProgramBlock extends StatelessWidget {
  final EpgProgram program;
  final VoidCallback onTap;
  const _ProgramBlock({required this.program, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isNow = program.isCurrentlyRunning;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: isNow
            ? AppColors.secondary.withValues(alpha: 0.25)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            decoration: isNow
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.secondary, width: 1.5),
                  )
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            alignment: Alignment.centerLeft,
            child: Text(
              program.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: isNow ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
