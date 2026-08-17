import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ob die App gerade auf einem Android-TV-Geraet laeuft. Wird einmalig beim
/// Start in main.dart ermittelt und hier ueberschrieben (siehe
/// storageServiceProvider fuer das gleiche Muster) - so koennen alle
/// Widgets synchron darauf zugreifen, ohne FutureBuilder ueberall.
final isAndroidTvProvider = Provider<bool>((ref) => false);
