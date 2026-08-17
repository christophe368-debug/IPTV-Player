import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/channel.dart';
import '../providers/settings_provider.dart';
import '../screens/settings/settings_screen.dart';

enum _ChannelAction { toggleLock, toggleHidden }

/// Drei-Punkte-Menue zum Sperren (Eltern-PIN) und Ausblenden eines
/// einzelnen Senders/Films/einer Serie. Wiederverwendet in Senderliste,
/// Favoriten und Suche, damit sich das Verhalten ueberall gleich anfuehlt.
class ChannelActionsMenu extends ConsumerWidget {
  final String profileId;
  final Channel channel;
  const ChannelActionsMenu({super.key, required this.profileId, required this.channel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPin = ref.watch(hasParentalPinProvider);
    final isLocked = ref.watch(lockedChannelsProvider(profileId)).contains(channel.favoriteKey);
    final isHidden = ref.watch(hiddenChannelsProvider(profileId)).contains(channel.favoriteKey);

    return PopupMenuButton<_ChannelAction>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Weitere Optionen',
      onSelected: (action) {
        switch (action) {
          case _ChannelAction.toggleLock:
            ref.read(lockedChannelsProvider(profileId).notifier).toggle(channel.favoriteKey);
          case _ChannelAction.toggleHidden:
            ref.read(hiddenChannelsProvider(profileId).notifier).toggle(channel.favoriteKey);
        }
      },
      itemBuilder: (context) => [
        if (hasPin)
          PopupMenuItem(
            value: _ChannelAction.toggleLock,
            child: ListTile(
              leading: Icon(isLocked ? Icons.lock_open : Icons.lock),
              title: Text(isLocked ? 'Sperre aufheben' : 'Sperren'),
            ),
          ),
        PopupMenuItem(
          value: _ChannelAction.toggleHidden,
          child: ListTile(
            leading: Icon(isHidden ? Icons.visibility : Icons.visibility_off),
            title: Text(isHidden ? 'Einblenden' : 'Ausblenden'),
          ),
        ),
      ],
    );
  }
}

/// Prueft, ob [channel] gesperrt ist, und fragt bei Bedarf die Eltern-PIN
/// ab. Gibt true zurueck, wenn die Wiedergabe fortgesetzt werden darf.
Future<bool> requestChannelUnlockIfNeeded(
  BuildContext context,
  WidgetRef ref,
  String profileId,
  Channel channel,
) async {
  final isLocked = ref.read(lockedChannelsProvider(profileId)).contains(channel.favoriteKey);
  if (!isLocked) return true;
  return requestParentalPin(context, ref);
}
