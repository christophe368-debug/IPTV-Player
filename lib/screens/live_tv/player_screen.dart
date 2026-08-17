import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../providers/platform_provider.dart';

const _pipChannel = MethodChannel('iptv_player/pip');

/// Vollbild-Wiedergabe eines Streams (Live-TV, VOD, Serien-Episode oder
/// Timeshift/Catchup-Ausschnitt). Nutzt media_kit (libmpv), da es im
/// Gegensatz zum einfachen Flutter video_player auch rohe MPEG-TS-Streams
/// zuverlaessig abspielt, was bei IPTV-Anbietern sehr haeufig vorkommt.
class PlayerScreen extends ConsumerStatefulWidget {
  final String title;
  final String streamUrl;
  const PlayerScreen({super.key, required this.title, required this.streamUrl});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late final Player _player;
  late final VideoController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);

    _player.stream.error.listen((error) {
      if (mounted) setState(() => _errorMessage = error);
    });

    _player.open(Media(widget.streamUrl));

    // Waehrend der Wiedergabe: Bildschirm nicht abschalten und im
    // Querformat bleiben (typisch fuer Video-Vollbild).
    WakelockPlus.enable();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _player.dispose();
    super.dispose();
  }

  Future<void> _enterPip() async {
    if (!Platform.isAndroid) return;
    try {
      final ok = await _pipChannel.invokeMethod<bool>('enterPip');
      if (ok != true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bild-in-Bild wird auf diesem Geraet nicht unterstuetzt.')),
        );
      }
    } on PlatformException {
      // Ignorieren - PiP ist ein Komfort-Feature, kein kritischer Pfad.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTv = ref.watch(isAndroidTvProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        actions: [
          // Picture-in-Picture ergibt auf einem Fernseher keinen Sinn (kein
          // Fenster-Konzept, keine sinnvolle Fernbedienungs-Geste dafuer).
          if (Platform.isAndroid && !isTv)
            IconButton(
              icon: const Icon(Icons.picture_in_picture_alt),
              tooltip: 'Bild-in-Bild',
              onPressed: _enterPip,
            ),
        ],
      ),
      body: Center(
        child: _errorMessage != null
            ? _PlaybackError(message: _errorMessage!)
            : Video(controller: _controller),
      ),
    );
  }
}

class _PlaybackError extends StatelessWidget {
  final String message;
  const _PlaybackError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            'Wiedergabe fehlgeschlagen:\n$message',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
