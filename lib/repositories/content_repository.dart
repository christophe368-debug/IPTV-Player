import 'dart:io';
import '../models/category.dart';
import '../models/channel.dart';
import '../models/epg_program.dart';
import '../services/m3u_parser_service.dart';
import '../services/xmltv_service.dart';
import '../services/xtream_service.dart';

/// Einheitliche Schnittstelle, um Kategorien/Sender/Filme/Serien zu laden -
/// unabhaengig davon, ob die Daten von einer Xtream-Codes-API oder einer
/// M3U-Playlist kommen. Die UI-Screens muessen sich so nicht um die
/// jeweilige Quelle kuemmern.
abstract class ContentRepository {
  Future<List<Category>> getCategories(StreamType type);
  Future<List<Channel>> getChannels(StreamType type, {String? categoryId});

  /// Programmfuehrer-Eintraege fuer einen Sender. Liefert eine leere Liste,
  /// wenn fuer diese Quelle kein EPG verfuegbar ist.
  Future<List<EpgProgram>> getEpg(Channel channel);

  /// URL einer XMLTV-Datei mit dem EPG *aller* Sender auf einmal (fuer die
  /// Raster-Ansicht/TV-Guide effizienter als getEpg() pro Sender einzeln
  /// aufzurufen). Null, wenn nicht verfuegbar.
  Future<String?> getEpgSourceUrl();
}

class XtreamContentRepository implements ContentRepository {
  final XtreamService service;
  XtreamContentRepository(this.service);

  @override
  Future<List<Category>> getCategories(StreamType type) => service.getCategories(type);

  @override
  Future<List<Channel>> getChannels(StreamType type, {String? categoryId}) =>
      service.getStreams(type, categoryId: categoryId);

  @override
  Future<List<EpgProgram>> getEpg(Channel channel) => service.getEpgPrograms(channel.id);

  @override
  Future<String?> getEpgSourceUrl() async => service.buildXmltvUrl();
}

/// Fuer M3U-Quellen (URL oder lokale Datei). M3U-Playlists liefern keine
/// getrennten VOD/Serien-Endpunkte wie Xtream - wir behandeln sie deshalb
/// vorerst als reine Live-TV-Liste. Das Parse-Ergebnis wird zwischengespeichert,
/// damit nicht bei jedem Kategoriewechsel neu geladen/geparst werden muss.
class M3uContentRepository implements ContentRepository {
  final String source;
  final bool isLocalFile;
  final XmltvService _xmltvService = XmltvService();
  M3uParseResult? _cache;

  M3uContentRepository({required this.source, required this.isLocalFile});

  Future<M3uParseResult> _load() async {
    final cached = _cache;
    if (cached != null) return cached;
    final result = isLocalFile
        ? M3uParserService().parseContent(await File(source).readAsString())
        : await M3uParserService().parseFromUrl(source);
    _cache = result;
    return result;
  }

  @override
  Future<List<Category>> getCategories(StreamType type) async {
    if (type != StreamType.live) return [];
    return (await _load()).categories;
  }

  @override
  Future<List<Channel>> getChannels(StreamType type, {String? categoryId}) async {
    if (type != StreamType.live) return [];
    final channels = (await _load()).channels;
    if (categoryId == null) return channels;
    return channels.where((c) => c.categoryId == categoryId).toList();
  }

  @override
  Future<List<EpgProgram>> getEpg(Channel channel) async {
    final epgUrl = (await _load()).epgUrl;
    final tvgId = channel.epgChannelId;
    if (epgUrl == null || tvgId == null || tvgId.isEmpty) return [];
    return _xmltvService.getPrograms(epgUrl, tvgId);
  }

  @override
  Future<String?> getEpgSourceUrl() async => (await _load()).epgUrl;
}
