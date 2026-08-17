import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../models/channel.dart';
import '../models/profile.dart';
import '../providers/content_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/settings/settings_screen.dart';
import 'tv_focus_highlight.dart';

/// Gemeinsame Kategorien-Liste fuer Live-TV/Filme/Serien, inkl.
/// Kindersicherung: Kategorien lassen sich sperren (Schloss-Symbol) und
/// erfordern dann die Eltern-PIN, bevor man sie oeffnen kann.
class CategoryListView extends ConsumerWidget {
  final Profile profile;
  final StreamType type;
  final IconData icon;
  final void Function(BuildContext context, Category category) onOpen;

  const CategoryListView({
    super.key,
    required this.profile,
    required this.type,
    required this.icon,
    required this.onOpen,
  });

  String _lockKey(Category category) => '${type.name}_${category.id}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (profile: profile, type: type);
    final categoriesAsync = ref.watch(categoriesProvider(query));
    final hasPin = ref.watch(hasParentalPinProvider);
    final lockedKeys = ref.watch(lockedCategoriesProvider(profile.id));

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text(err.toString().replaceFirst('Exception: ', ''))),
      data: (categories) {
        if (categories.isEmpty) {
          return const Center(child: Text('Keine Kategorien gefunden.'));
        }
        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, i) {
            final category = categories[i];
            final key = _lockKey(category);
            final isLocked = lockedKeys.contains(key);

            return TvFocusHighlight(
              child: ListTile(
                autofocus: i == 0,
                leading: Icon(icon),
                title: Text(category.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasPin)
                      IconButton(
                        icon: Icon(isLocked ? Icons.lock : Icons.lock_open),
                        tooltip: isLocked ? 'Sperre aufheben' : 'Kategorie sperren',
                        onPressed: () =>
                            ref.read(lockedCategoriesProvider(profile.id).notifier).toggle(key),
                      ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () async {
                  if (isLocked) {
                    final allowed = await requestParentalPin(context, ref);
                    if (!allowed) return;
                  }
                  if (context.mounted) onOpen(context, category);
                },
              ),
            );
          },
        );
      },
    );
  }
}
