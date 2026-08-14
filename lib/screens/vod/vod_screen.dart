import 'package:flutter/material.dart';
import '../../models/channel.dart';
import '../../models/profile.dart';
import '../../widgets/category_list.dart';
import 'vod_list_screen.dart';

/// Filme (VOD): zeigt die Kategorien. Nur fuer Xtream-Profile verfuegbar,
/// da M3U-Playlists keine getrennte VOD-Struktur liefern.
class VodScreen extends StatelessWidget {
  final Profile profile;
  const VodScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return CategoryListView(
      profile: profile,
      type: StreamType.vod,
      icon: Icons.movie_outlined,
      onOpen: (context, category) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VodListScreen(profile: profile, category: category),
        ),
      ),
    );
  }
}
