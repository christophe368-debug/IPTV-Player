import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/profile_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final hasPin = ref.watch(hasParentalPinProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        children: [
          const _SectionHeader('Darstellung'),
          RadioGroup<ThemeMode>(
            groupValue: themeMode,
            onChanged: (mode) => ref.read(themeModeProvider.notifier).setMode(mode!),
            child: const Column(
              children: [
                RadioListTile<ThemeMode>(title: Text('System'), value: ThemeMode.system),
                RadioListTile<ThemeMode>(title: Text('Hell'), value: ThemeMode.light),
                RadioListTile<ThemeMode>(title: Text('Dunkel'), value: ThemeMode.dark),
              ],
            ),
          ),
          const Divider(),
          const _SectionHeader('Kindersicherung'),
          ListTile(
            leading: Icon(hasPin ? Icons.lock : Icons.lock_open),
            title: Text(hasPin ? 'Eltern-PIN geaendert/entfernen' : 'Eltern-PIN einrichten'),
            subtitle: const Text('Schuetzt als gesperrt markierte Kategorien mit einer PIN.'),
            onTap: () => _showPinSetupDialog(context, ref, hasPin),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              'Kategorien lassen sich in Live-TV/Filme/Serien ueber das '
              'Schloss-Symbol sperren, sobald eine PIN eingerichtet ist.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPinSetupDialog(BuildContext context, WidgetRef ref, bool hasPin) async {
    final storage = ref.read(storageServiceProvider);
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(hasPin ? 'PIN aendern' : 'PIN einrichten'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: const InputDecoration(labelText: '4-6-stellige PIN'),
        ),
        actions: [
          if (hasPin)
            TextButton(
              onPressed: () async {
                await storage.clearParentalPin();
                ref.invalidate(hasParentalPinProvider);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text('PIN entfernen'),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () async {
              final pin = controller.text.trim();
              if (pin.length < 4) return;
              await storage.setParentalPin(pin);
              ref.invalidate(hasParentalPinProvider);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

/// Zeigt einen PIN-Abfrage-Dialog und gibt true zurueck, wenn die PIN
/// korrekt eingegeben wurde (bzw. wenn gar keine PIN eingerichtet ist).
Future<bool> requestParentalPin(BuildContext context, WidgetRef ref) async {
  final storage = ref.read(storageServiceProvider);
  if (!storage.hasParentalPin) return true;

  final controller = TextEditingController();
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('PIN erforderlich'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        obscureText: true,
        maxLength: 6,
        decoration: const InputDecoration(labelText: 'PIN eingeben'),
        onSubmitted: (value) {
          Navigator.of(dialogContext).pop(storage.checkParentalPin(value));
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(storage.checkParentalPin(controller.text)),
          child: const Text('Bestaetigen'),
        ),
      ],
    ),
  );
  return result ?? false;
}
