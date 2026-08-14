import 'package:flutter/material.dart';
import '../../models/channel.dart';
import '../../models/profile.dart';
import '../../widgets/category_list.dart';
import 'channel_list_screen.dart';

/// Zeigt die Live-TV-Kategorien (z.B. "Sport", "Nachrichten") des aktiven
/// Profils. Tippen auf eine Kategorie oeffnet die zugehoerige Senderliste.
class LiveTvScreen extends StatelessWidget {
  final Profile profile;
  const LiveTvScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return CategoryListView(
      profile: profile,
      type: StreamType.live,
      icon: Icons.live_tv,
      onOpen: (context, category) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChannelListScreen(profile: profile, category: category),
        ),
      ),
    );
  }
}
