import 'dart:io';
import 'package:flutter/services.dart';

const _platformChannel = MethodChannel('iptv_player/platform');

/// Fragt plattformspezifische Infos ab, die es in Flutter selbst nicht gibt.
class PlatformService {
  /// Erkennt, ob die App gerade auf einem Android-TV-Geraet laeuft (nicht
  /// auf einem normalen Handy/Tablet). Wird fuer die 10-Fuss-UI-Anpassungen
  /// gebraucht (groessere Elemente, sichtbare Fokus-Hervorhebung fuer
  /// D-Pad-Navigation, Seiten- statt Bottom-Navigation).
  Future<bool> isAndroidTv() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _platformChannel.invokeMethod<bool>('isAndroidTv');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
