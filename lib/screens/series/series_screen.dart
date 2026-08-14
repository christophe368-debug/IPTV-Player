import 'package:flutter/material.dart';
import '../../models/channel.dart';
import '../../models/profile.dart';
import '../../widgets/category_list.dart';
import 'series_list_screen.dart';

/// Serien: zeigt die Kategorien. Nur fuer Xtream-Profile verfuegbar.
class SeriesScreen extends StatelessWidget {
  final Profile profile;
  const SeriesScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return CategoryListView(
      profile: profile,
      type: StreamType.series,
      icon: Icons.tv_outlined,
      onOpen: (context, category) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SeriesListScreen(profile: profile, category: category),
        ),
      ),
    );
  }
}
