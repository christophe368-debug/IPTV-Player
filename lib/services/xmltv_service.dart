import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/epg_program.dart';

/// Laedt und parst XMLTV-Dateien - das Standardformat fuer EPG-Daten bei
/// M3U-basierten IPTV-Playlists (referenziert ueber `url-tvg` im
/// #EXTM3U-Header). Wird oft gzip-komprimiert (.xml.gz) ausgeliefert.
class XmltvService {
  /// Cache: einmal geladene/geparste XMLTV-Dokumente pro URL, damit nicht
  /// fuer jeden Sender die (potenziell grosse) Datei erneut heruntergeladen
  /// werden muss.
  final Map<String, Map<String, List<EpgProgram>>> _cache = {};

  Future<List<EpgProgram>> getPrograms(String xmltvUrl, String channelId) async {
    final byChannel = _cache[xmltvUrl] ?? await _loadAndParse(xmltvUrl);
    _cache[xmltvUrl] = byChannel;
    return byChannel[channelId] ?? [];
  }

  Future<Map<String, List<EpgProgram>>> _loadAndParse(String url) async {
    final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw Exception('EPG konnte nicht geladen werden (Status ${res.statusCode})');
    }

    String xmlContent;
    final looksGzipped = url.endsWith('.gz') || (res.bodyBytes.length > 2 && res.bodyBytes[0] == 0x1f && res.bodyBytes[1] == 0x8b);
    if (looksGzipped) {
      xmlContent = utf8.decode(gzip.decode(res.bodyBytes));
    } else {
      xmlContent = utf8.decode(res.bodyBytes);
    }

    final document = XmlDocument.parse(xmlContent);
    final byChannel = <String, List<EpgProgram>>{};

    for (final node in document.findAllElements('programme')) {
      final channelId = node.getAttribute('channel');
      final startRaw = node.getAttribute('start');
      final stopRaw = node.getAttribute('stop');
      if (channelId == null || startRaw == null || stopRaw == null) continue;

      final start = _parseXmltvDate(startRaw);
      final stop = _parseXmltvDate(stopRaw);
      if (start == null || stop == null) continue;

      final title = node.findElements('title').firstOrNull?.innerText ?? 'Unbekannt';
      final desc = node.findElements('desc').firstOrNull?.innerText;

      byChannel.putIfAbsent(channelId, () => []).add(
            EpgProgram(title: title, description: desc, start: start, end: stop),
          );
    }

    return byChannel;
  }

  /// XMLTV-Datumsformat: "yyyyMMddHHmmss +HHMM" (Zeitzone optional).
  DateTime? _parseXmltvDate(String raw) {
    final match = RegExp(r'^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})\s*([+-]\d{4})?$').firstMatch(raw.trim());
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final hour = int.parse(match.group(4)!);
    final minute = int.parse(match.group(5)!);
    final second = int.parse(match.group(6)!);
    final offset = match.group(7);

    var utcDate = DateTime.utc(year, month, day, hour, minute, second);
    if (offset != null && offset.length == 5) {
      final sign = offset[0] == '-' ? -1 : 1;
      final offsetHours = int.parse(offset.substring(1, 3));
      final offsetMinutes = int.parse(offset.substring(3, 5));
      utcDate = utcDate.subtract(Duration(hours: sign * offsetHours, minutes: sign * offsetMinutes));
    }
    return utcDate.toLocal();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
