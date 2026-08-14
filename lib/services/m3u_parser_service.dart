import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/channel.dart';

class M3uParseResult {
  final List<Channel> channels;
  final List<Category> categories;
  /// EPG-URL (XMLTV), falls die Playlist eine per `url-tvg`/`x-tvg-url`
  /// im #EXTM3U-Header angibt. Kann null sein, wenn keine EPG-Quelle
  /// bekannt ist.
  final String? epgUrl;
  M3uParseResult(this.channels, this.categories, {this.epgUrl});
}

/// Parst eine M3U/M3U8-Playlist (Standardformat, z.B. von IPTV-Anbietern
/// oder selbst erstellt). Erwartetes Format pro Eintrag:
///
/// #EXTINF:-1 tvg-id="..." tvg-logo="..." group-title="Sport",Sendername
/// http://server/pfad/zum/stream.m3u8
class M3uParserService {
  /// Laedt eine Playlist von einer URL herunter und parst sie.
  Future<M3uParseResult> parseFromUrl(String url) async {
    final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw Exception('Playlist konnte nicht geladen werden (Status ${res.statusCode})');
    }
    // res.body wuerde ohne explizites Content-Type-Charset in Latin-1
    // dekodieren und Umlaute zerstoeren (z.B. "Allgaeu" -> "AllgÃ¤u").
    // IPTV-Playlists sind praktisch immer UTF-8, egal was der Header sagt.
    return parseContent(utf8.decode(res.bodyBytes, allowMalformed: true));
  }

  /// Parst den Inhalt einer bereits geladenen/eingelesenen M3U-Datei.
  M3uParseResult parseContent(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    final channels = <Channel>[];
    final categoriesByName = <String, Category>{};

    String? pendingName;
    String? pendingLogo;
    String? pendingGroup;
    String? pendingTvgId;
    String? epgUrl;
    var index = 0;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTM3U')) {
        epgUrl = _extractAttr(line, 'url-tvg') ?? _extractAttr(line, 'x-tvg-url');
      } else if (line.startsWith('#EXTINF')) {
        pendingName = _extractTitle(line);
        pendingLogo = _extractAttr(line, 'tvg-logo');
        pendingGroup = _extractAttr(line, 'group-title') ?? 'Ohne Kategorie';
        pendingTvgId = _extractAttr(line, 'tvg-id');
      } else if (line.startsWith('#')) {
        // Andere Meta-Zeilen (#EXTGRP, ...) ignorieren wir vorerst.
        continue;
      } else {
        // Das ist eine URL-Zeile - gehoert zum zuletzt gesehenen #EXTINF.
        final groupName = pendingGroup ?? 'Ohne Kategorie';
        final category = categoriesByName.putIfAbsent(
          groupName,
          () => Category(id: groupName, name: groupName, streamType: StreamType.live),
        );

        channels.add(Channel(
          id: 'm3u_${index++}',
          name: pendingName ?? 'Unbenannt',
          categoryId: category.id,
          logoUrl: pendingLogo,
          streamUrl: line,
          streamType: StreamType.live,
          epgChannelId: pendingTvgId,
        ));

        pendingName = null;
        pendingLogo = null;
        pendingGroup = null;
        pendingTvgId = null;
      }
    }

    return M3uParseResult(channels, categoriesByName.values.toList(), epgUrl: epgUrl);
  }

  String _extractTitle(String extinfLine) {
    // Alles nach dem letzten Komma in der #EXTINF-Zeile ist der Sendername.
    final commaIndex = extinfLine.lastIndexOf(',');
    if (commaIndex == -1 || commaIndex == extinfLine.length - 1) return 'Unbenannt';
    return extinfLine.substring(commaIndex + 1).trim();
  }

  String? _extractAttr(String line, String attrName) {
    final match = RegExp('$attrName="([^"]*)"').firstMatch(line);
    return match?.group(1);
  }
}
