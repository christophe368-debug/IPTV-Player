import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Vollbild-Wiedergabe eines Streams (Live-TV, VOD oder Serien-Episode).
/// Nutzt media_kit (libmpv), da es im Gegensatz zum einfachen Flutter
/// video_player auch rohe MPEG-TS-Streams zuverlaessig abspielt, was bei
/// IPTV-Anbietern sehr haeufig vorkommt.
class PlayerScreen extends StatefulWidget {
  final String title;
  final String streamUrl;
  const PlayerScreen({super.key, required this.title, required this.streamUrl});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player;
  late final VideoController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);

    // Bildschirm waehrend der Wiedergabe im Querformat und ohne
    // Standby-Sperre halten fuehren wir in einem spaeteren Schritt ein.
    _player.stream.error.listen((error) {
      if (mounted) setState(() => _errorMessage = error);
    });

    _player.open(Media(widget.streamUrl));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
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
