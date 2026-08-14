import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iptv_player/providers/profile_provider.dart';
import 'package:iptv_player/screens/auth/profile_list_screen.dart';
import 'package:iptv_player/services/storage_service.dart';

void main() {
  late Directory tempDir;
  late StorageService storage;

  setUp(() async {
    // Eigenes Temp-Verzeichnis statt Hive.initFlutter(): das vermeidet den
    // path_provider-Plattform-Kanal, den es im Testlauf nicht gibt (fuehrte
    // vorher zu einem 10-Minuten-Timeout statt eines Testfehlers).
    tempDir = await Directory.systemTemp.createTemp('iptv_player_test_');
    storage = StorageService();
    await storage.init(testDirectoryPath: tempDir.path);
  });

  tearDown(() async {
    // Hive haelt die Box-Dateien offen (Windows sperrt offene Dateien) -
    // erst schliessen, dann kann der Temp-Ordner geloescht werden.
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('Profile-Liste zeigt Leerzustand, wenn noch kein Profil existiert', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const MaterialApp(home: ProfileListScreen()),
      ),
    );

    expect(find.text('Noch kein Profil eingerichtet'), findsOneWidget);
    expect(find.text('Profil hinzufuegen'), findsOneWidget);
  });
}
