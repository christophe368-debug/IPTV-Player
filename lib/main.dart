import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'providers/profile_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/auth/profile_list_screen.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // media_kit (unsere Video-Engine) muss einmalig initialisiert werden.
  MediaKit.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: const IptvPlayerApp(),
    ),
  );
}

class IptvPlayerApp extends ConsumerWidget {
  const IptvPlayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'IPTV Player',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const ProfileListScreen(),
    );
  }
}
