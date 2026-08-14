import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import 'live_tv/live_tv_screen.dart';

/// Hauptbildschirm nach dem Login: Bottom-Navigation zwischen Live-TV, VOD,
/// Serien, Favoriten und Suche. VOD/Serien/Favoriten/Suche werden in
/// spaeteren Schritten mit echtem Inhalt gefuellt.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(activeProfileProvider);
    if (profile == null) {
      // Sollte praktisch nicht vorkommen (Profil wird vor Navigation gesetzt),
      // aber sicherheitshalber zurueck zur Profilauswahl statt abzustuerzen.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tabs = [
      LiveTvScreen(profile: profile),
      const _ComingSoon(label: 'Filme (VOD)'),
      const _ComingSoon(label: 'Serien'),
      const _ComingSoon(label: 'Favoriten'),
      const _ComingSoon(label: 'Suche'),
    ];

    const titles = ['Live TV', 'Filme', 'Serien', 'Favoriten', 'Suche'];

    return Scaffold(
      appBar: AppBar(
        title: Text('${titles[_tabIndex]} - ${profile.name}'),
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
      body: IndexedStack(index: _tabIndex, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.live_tv), label: 'Live TV'),
          NavigationDestination(icon: Icon(Icons.movie_outlined), label: 'Filme'),
          NavigationDestination(icon: Icon(Icons.tv_outlined), label: 'Serien'),
          NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Favoriten'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Suche'),
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  final String label;
  const _ComingSoon({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text('$label folgt in einem der naechsten Schritte'),
        ],
      ),
    );
  }
}
