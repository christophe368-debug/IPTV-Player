import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'providers/platform_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/auth/profile_list_screen.dart';
import 'services/platform_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // media_kit (unsere Video-Engine) muss einmalig initialisiert werden.
  MediaKit.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  final isAndroidTv = await PlatformService().isAndroidTv();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
        isAndroidTvProvider.overrideWithValue(isAndroidTv),
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
    final isTv = ref.watch(isAndroidTvProvider);

    // Auf einem Fernseher wird aus 3+ Metern Entfernung geschaut - etwas
    // groessere Schrift/Icons und mehr Abstand zwischen den Elementen als
    // auf einem Handy in der Hand.
    final visualDensity = isTv ? VisualDensity.comfortable : VisualDensity.standard;
    final textScaler = isTv ? const TextScaler.linear(1.15) : TextScaler.noScaling;

    return MaterialApp(
      title: 'IPTV Player',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      darkTheme: AppTheme.dark().copyWith(visualDensity: visualDensity),
      theme: AppTheme.light().copyWith(visualDensity: visualDensity),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        );
      },
      home: const ProfileListScreen(),
    );
  }
}
