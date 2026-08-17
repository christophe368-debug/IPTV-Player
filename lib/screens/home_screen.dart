import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import '../providers/platform_provider.dart';
import '../providers/profile_provider.dart';
import 'favorites/favorites_screen.dart';
import 'live_tv/live_tv_screen.dart';
import 'search/search_screen.dart';
import 'series/series_screen.dart';
import 'settings/settings_screen.dart';
import 'vod/vod_screen.dart';

/// Hauptbildschirm nach dem Login: Bottom-Navigation zwischen Live-TV, VOD,
/// Serien, Favoriten und Suche. VOD/Serien stehen nur bei Xtream-Profilen
/// zur Verfuegung, da M3U-Playlists keine getrennte Struktur dafuer liefern.
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isXtream = profile.type == ProfileType.xtream;
    final isTv = ref.watch(isAndroidTvProvider);

    final tabs = [
      LiveTvScreen(profile: profile),
      isXtream ? VodScreen(profile: profile) : const _NotAvailableForM3u(feature: 'Filme'),
      isXtream ? SeriesScreen(profile: profile) : const _NotAvailableForM3u(feature: 'Serien'),
      FavoritesScreen(profile: profile),
      SearchScreen(profile: profile),
    ];

    const titles = ['Live TV', 'Filme', 'Serien', 'Favoriten', 'Suche'];
    const icons = [
      Icons.live_tv,
      Icons.movie_outlined,
      Icons.tv_outlined,
      Icons.favorite_border,
      Icons.search,
    ];

    final appBar = AppBar(
      title: Text('${titles[_tabIndex]} - ${profile.name}'),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Einstellungen',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.switch_account),
          tooltip: 'Profil wechseln',
          onPressed: () {
            ref.read(activeProfileIdProvider.notifier).state = null;
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ],
    );

    // Auf Android TV gibt es keine untere Bildschirmkante, die man mit einer
    // Fernbedienung bequem erreicht - eine seitliche Navigationsleiste ist
    // mit dem D-Pad (rauf/runter) viel natuerlicher zu bedienen.
    if (isTv) {
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _tabIndex,
              onDestinationSelected: (i) => setState(() => _tabIndex = i),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (var i = 0; i < titles.length; i++)
                  NavigationRailDestination(
                    icon: Icon(icons[i]),
                    label: Text(titles[i]),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: IndexedStack(index: _tabIndex, children: tabs)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: IndexedStack(index: _tabIndex, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: [
          for (var i = 0; i < titles.length; i++)
            NavigationDestination(icon: Icon(icons[i]), label: titles[i]),
        ],
      ),
    );
  }
}

class _NotAvailableForM3u extends StatelessWidget {
  final String feature;
  const _NotAvailableForM3u({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              '$feature sind fuer M3U-Playlists nicht verfuegbar.\n'
              'M3U-Listen liefern keine getrennte $feature-Struktur wie Xtream Codes.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
