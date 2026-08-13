import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/profile.dart';
import '../../providers/profile_provider.dart';
import '../home_screen.dart';
import 'add_profile_screen.dart';

/// Startbildschirm der App: zeigt alle gespeicherten IPTV-Profile
/// (Xtream-Zugaenge, M3U-Playlists) und erlaubt das Hinzufuegen neuer.
class ProfileListScreen extends ConsumerWidget {
  const ProfileListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Meine Profile')),
      body: profiles.isEmpty
          ? _EmptyState(onAdd: () => _openAddProfile(context))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: profiles.length,
              itemBuilder: (context, i) {
                final profile = profiles[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?')),
                    title: Text(profile.name),
                    subtitle: Text(_typeLabel(profile.type)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => ref.read(profilesProvider.notifier).remove(profile.id),
                    ),
                    onTap: () => _selectProfile(context, ref, profile),
                  ),
                );
              },
            ),
      floatingActionButton: profiles.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => _openAddProfile(context),
              child: const Icon(Icons.add),
            ),
    );
  }

  void _selectProfile(BuildContext context, WidgetRef ref, Profile profile) {
    ref.read(activeProfileIdProvider.notifier).state = profile.id;
    ref.read(storageServiceProvider).setActiveProfileId(profile.id);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  void _openAddProfile(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddProfileScreen()));
  }

  String _typeLabel(ProfileType type) {
    return switch (type) {
      ProfileType.xtream => 'Xtream Codes',
      ProfileType.m3uUrl => 'M3U-Playlist (URL)',
      ProfileType.m3uFile => 'M3U-Datei (lokal)',
    };
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.live_tv, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Noch kein Profil eingerichtet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fuege deinen IPTV-Zugang hinzu (Xtream Codes, M3U-Link oder lokale Datei).',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Profil hinzufuegen'),
            ),
          ],
        ),
      ),
    );
  }
}
