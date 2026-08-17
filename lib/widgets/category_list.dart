import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../models/channel.dart';
import '../models/profile.dart';
import '../providers/content_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/settings/settings_screen.dart';
import 'tv_focus_highlight.dart';

/// Gemeinsame Kategorien-Liste fuer Live-TV/Filme/Serien:
/// - Kindersicherung (Kategorie mit Eltern-PIN sperren)
/// - Kategorien ausblenden (ohne PIN, einfach "brauche ich nicht")
/// - Kategorien umbenennen (eigener Anzeigename)
class CategoryListView extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<CategoryListView> createState() => _CategoryListViewState();
}

class _CategoryListViewState extends ConsumerState<CategoryListView> {
  bool _showHidden = false;

  String _lockKey(Category category) => '${widget.type.name}_${category.id}';

  @override
  Widget build(BuildContext context) {
    final query = (profile: widget.profile, type: widget.type);
    final categoriesAsync = ref.watch(categoriesProvider(query));
    final hasPin = ref.watch(hasParentalPinProvider);
    final lockedKeys = ref.watch(lockedCategoriesProvider(widget.profile.id));
    final hiddenKeys = ref.watch(hiddenCategoriesProvider(widget.profile.id));
    final nameOverrides = ref.watch(categoryNameOverridesProvider(widget.profile.id));

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text(err.toString().replaceFirst('Exception: ', ''))),
      data: (categories) {
        if (categories.isEmpty) {
          return const Center(child: Text('Keine Kategorien gefunden.'));
        }

        final visible = categories.where((c) {
          final isHidden = hiddenKeys.contains(_lockKey(c));
          return _showHidden || !isHidden;
        }).toList();

        return Column(
          children: [
            if (hiddenKeys.isNotEmpty)
              SwitchListTile(
                dense: true,
                title: const Text('Ausgeblendete Kategorien anzeigen'),
                value: _showHidden,
                onChanged: (value) => setState(() => _showHidden = value),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: visible.length,
                itemBuilder: (context, i) {
                  final category = visible[i];
                  final key = _lockKey(category);
                  final isLocked = lockedKeys.contains(key);
                  final isHidden = hiddenKeys.contains(key);
                  final displayName = nameOverrides[key] ?? category.name;

                  return TvFocusHighlight(
                    child: ListTile(
                      autofocus: i == 0,
                      leading: Icon(widget.icon),
                      title: Text(displayName, style: TextStyle(color: isHidden ? Colors.grey : null)),
                      subtitle: isHidden ? const Text('Ausgeblendet') : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PopupMenuButton<_CategoryAction>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (action) => _handleAction(
                              action,
                              category: category,
                              key: key,
                              isLocked: isLocked,
                              isHidden: isHidden,
                              currentName: displayName,
                            ),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: _CategoryAction.rename,
                                child: ListTile(
                                  leading: Icon(Icons.edit_outlined),
                                  title: Text('Umbenennen'),
                                ),
                              ),
                              if (hasPin)
                                PopupMenuItem(
                                  value: _CategoryAction.toggleLock,
                                  child: ListTile(
                                    leading: Icon(isLocked ? Icons.lock_open : Icons.lock),
                                    title: Text(isLocked ? 'Sperre aufheben' : 'Sperren'),
                                  ),
                                ),
                              PopupMenuItem(
                                value: _CategoryAction.toggleHidden,
                                child: ListTile(
                                  leading: Icon(isHidden ? Icons.visibility : Icons.visibility_off),
                                  title: Text(isHidden ? 'Einblenden' : 'Ausblenden'),
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () async {
                        if (isLocked) {
                          final allowed = await requestParentalPin(context, ref);
                          if (!allowed) return;
                        }
                        if (context.mounted) widget.onOpen(context, category.copyWith(name: displayName));
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleAction(
    _CategoryAction action, {
    required Category category,
    required String key,
    required bool isLocked,
    required bool isHidden,
    required String currentName,
  }) async {
    switch (action) {
      case _CategoryAction.rename:
        await _showRenameDialog(category: category, key: key, currentName: currentName);
      case _CategoryAction.toggleLock:
        await ref.read(lockedCategoriesProvider(widget.profile.id).notifier).toggle(key);
      case _CategoryAction.toggleHidden:
        await ref.read(hiddenCategoriesProvider(widget.profile.id).notifier).toggle(key);
    }
  }

  Future<void> _showRenameDialog({
    required Category category,
    required String key,
    required String currentName,
  }) async {
    final controller = TextEditingController(text: currentName);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kategorie umbenennen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Anzeigename'),
        ),
        actions: [
          if (currentName != category.name)
            TextButton(
              onPressed: () async {
                await ref
                    .read(categoryNameOverridesProvider(widget.profile.id).notifier)
                    .setName(key, null);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text('Original wiederherstellen'),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(categoryNameOverridesProvider(widget.profile.id).notifier)
                  .setName(key, controller.text);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}

enum _CategoryAction { rename, toggleLock, toggleHidden }
