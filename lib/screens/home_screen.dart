import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';

/// Platzhalter-Startbildschirm nach dem Login. Wird in einem der naechsten
/// Schritte durch die eigentliche Live-TV/VOD/Serien-Oberflaeche ersetzt.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(profile?.name ?? 'IPTV Player'),
        actions: [
          IconButton(
            icon: const Icon(Icons.switch_account),
            tooltip: 'Profil wechseln',
            onPressed: () {
              ref.read(activeProfileIdProvider.notifier).state = null;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.live_tv, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Eingeloggt als "${profile?.name}"',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Live-TV, VOD, Serien, EPG & mehr folgen im naechsten Schritt.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
