import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/channel.dart';
import '../../models/profile.dart';
import '../../providers/content_provider.dart';

/// Programmfuehrer (EPG) fuer einen einzelnen Sender: zeigt "Jetzt" und
/// die naechsten Sendungen mit Uhrzeit und Beschreibung.
class EpgScreen extends ConsumerWidget {
  final Profile profile;
  final Channel channel;
  const EpgScreen({super.key, required this.profile, required this.channel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final epgAsync = ref.watch(epgProvider((profile: profile, channel: channel)));

    return Scaffold(
      appBar: AppBar(title: Text('Programm - ${channel.name}')),
      body: epgAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(err.toString().replaceFirst('Exception: ', ''), textAlign: TextAlign.center),
          ),
        ),
        data: (programs) {
          if (programs.isEmpty) {
            return const Center(child: Text('Kein Programmfuehrer fuer diesen Sender verfuegbar.'));
          }
          final sorted = [...programs]..sort((a, b) => a.start.compareTo(b.start));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: sorted.length,
            separatorBuilder: (context, i) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final program = sorted[i];
              final isNow = program.isCurrentlyRunning;
              return ListTile(
                tileColor: isNow ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4) : null,
                leading: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_formatTime(program.start)),
                    Text(_formatTime(program.end), style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                title: Text(
                  program.title,
                  style: TextStyle(fontWeight: isNow ? FontWeight.bold : FontWeight.normal),
                ),
                subtitle: program.description != null && program.description!.isNotEmpty
                    ? Text(program.description!, maxLines: 2, overflow: TextOverflow.ellipsis)
                    : null,
                trailing: isNow ? const Chip(label: Text('Jetzt')) : null,
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
