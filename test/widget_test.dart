import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_player/providers/profile_provider.dart';
import 'package:iptv_player/screens/auth/profile_list_screen.dart';
import 'package:iptv_player/services/storage_service.dart';

void main() {
  testWidgets('Profile-Liste zeigt Leerzustand, wenn noch kein Profil existiert', (tester) async {
    final storage = StorageService();
    await storage.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const MaterialApp(home: ProfileListScreen()),
      ),
    );

    expect(find.text('Noch kein Profil eingerichtet'), findsOneWidget);
  });
}
