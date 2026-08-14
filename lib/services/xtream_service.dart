import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/channel.dart';
import '../models/episode.dart';
import '../models/epg_program.dart';
import '../models/media_details.dart';

/// Client fuer die "Xtream Codes API", das von den meisten kommerziellen
/// IPTV-Anbietern verwendete Format. Kommuniziert mit `player_api.php`
/// auf dem Server des Anbieters.
///
/// Doku (inoffiziell, aber weit verbreiteter Standard):
/// http://SERVER:PORT/player_api.php?username=U&password=P&action=...
class XtreamService {
  final String serverUrl;
  final String username;
  final String password;

  XtreamService({
    required this.serverUrl,
    required this.username,
    required this.password,
  });

  String get _base => serverUrl.endsWith('/')
      ? serverUrl.substring(0, serverUrl.length - 1)
      : serverUrl;

  Uri _apiUri(String action, [Map<String, String>? extra]) {
    return Uri.parse('$_base/player_api.php').replace(queryParameters: {
      'username': username,
      'password': password,
      if (action.isNotEmpty) 'action': action,
      ...?extra,
    });
  }

  /// Prueft die Zugangsdaten und liefert die Account-Infos zurueck.
  /// Wirft eine Exception, wenn Login fehlschlaegt.
  Future<Map<String, dynamic>> authenticate() async {
    final res = await http.get(_apiUri('')).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Server antwortete mit Status ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final auth = data['user_info']?['auth'];
    if (auth != 1 && auth != '1') {
      throw Exception('Login fehlgeschlagen - Zugangsdaten pruefen');
    }
    return data;
  }

  Future<List<Category>> getCategories(StreamType type) async {
    final action = switch (type) {
      StreamType.live => 'get_live_categories',
      StreamType.vod => 'get_vod_categories',
      StreamType.series => 'get_series_categories',
    };
    final res = await http.get(_apiUri(action)).timeout(const Duration(seconds: 15));
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => Category(
              id: e['category_id'].toString(),
              name: e['category_name'] as String? ?? '?',
              streamType: type,
            ))
        .toList();
  }

  Future<List<Channel>> getStreams(StreamType type, {String? categoryId}) async {
    final action = switch (type) {
      StreamType.live => 'get_live_streams',
      StreamType.vod => 'get_vod_streams',
      StreamType.series => 'get_series',
    };
    final res = await http
        .get(_apiUri(action, categoryId != null ? {'category_id': categoryId} : null))
        .timeout(const Duration(seconds: 20));
    final list = jsonDecode(res.body) as List<dynamic>;

    return list.map((e) {
      final streamId = (e['stream_id'] ?? e['series_id']).toString();
      // tv_archive/tv_archive_duration kommen nur bei Live-Sendern vor und
      // zeigen an, ob und wie viele Tage Timeshift/Catchup verfuegbar sind.
      final archiveFlag = e['tv_archive'];
      final hasArchive = archiveFlag == 1 || archiveFlag == '1' || archiveFlag == true;
      final archiveDays = int.tryParse(e['tv_archive_duration']?.toString() ?? '') ?? 0;

      return Channel(
        id: streamId,
        name: e['name'] as String? ?? '?',
        categoryId: (e['category_id'] ?? '').toString(),
        logoUrl: e['stream_icon'] as String? ?? e['cover'] as String?,
        streamUrl: type == StreamType.series ? '' : buildStreamUrl(type, streamId, e['container_extension']),
        streamType: type,
        epgChannelId: e['epg_channel_id'] as String?,
        catchupDays: hasArchive ? (archiveDays > 0 ? archiveDays : 1) : 0,
      );
    }).toList();
  }

  /// Baut die Wiedergabe-URL fuer einen Timeshift/Catchup-Ausschnitt.
  /// [start] ist der Beginn der gewuenschten Sendung, [duration] ihre Laenge.
  String buildTimeshiftUrl(String streamId, DateTime start, Duration duration) {
    final minutes = duration.inMinutes.clamp(1, 24 * 60);
    final formatted = '${start.year.toString().padLeft(4, '0')}-'
        '${start.month.toString().padLeft(2, '0')}-'
        '${start.day.toString().padLeft(2, '0')}:'
        '${start.hour.toString().padLeft(2, '0')}-'
        '${start.minute.toString().padLeft(2, '0')}';
    return '$_base/timeshift/$username/$password/$minutes/$formatted/$streamId.ts';
  }

  /// Baut die abspielbare Stream-URL fuer einen gegebenen Kanal/Film.
  String buildStreamUrl(StreamType type, String streamId, [dynamic extension]) {
    final ext = (extension as String?)?.isNotEmpty == true ? extension : (type == StreamType.live ? 'ts' : 'mp4');
    final segment = switch (type) {
      StreamType.live => 'live',
      StreamType.vod => 'movie',
      StreamType.series => 'series',
    };
    return '$_base/$segment/$username/$password/$streamId.$ext';
  }

  /// Holt die Episoden einer Serie (series_id aus getStreams(series)).
  Future<Map<String, dynamic>> getSeriesInfo(String seriesId) async {
    final res = await http
        .get(_apiUri('get_series_info', {'series_id': seriesId}))
        .timeout(const Duration(seconds: 15));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Detailinfos (Beschreibung, Besetzung, ...) zu einem Film.
  Future<MediaDetails> getVodInfo(String vodId) async {
    final res = await http
        .get(_apiUri('get_vod_info', {'vod_id': vodId}))
        .timeout(const Duration(seconds: 15));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final info = data['info'] as Map<String, dynamic>? ?? {};
    return _mediaDetailsFromInfo(info);
  }

  /// Detailinfos + nach Staffel gruppierte Episoden einer Serie.
  Future<({MediaDetails details, Map<int, List<Episode>> seasons})> getSeriesDetails(
    String seriesId,
  ) async {
    final data = await getSeriesInfo(seriesId);
    final info = data['info'] as Map<String, dynamic>? ?? {};
    final details = _mediaDetailsFromInfo(info);

    final episodesRaw = data['episodes'] as Map<String, dynamic>? ?? {};
    final seasons = <int, List<Episode>>{};
    episodesRaw.forEach((seasonKey, list) {
      final seasonNum = int.tryParse(seasonKey) ?? 0;
      final episodes = (list as List<dynamic>).map((e) {
        final map = e as Map<String, dynamic>;
        final episodeId = map['id'].toString();
        return Episode(
          id: episodeId,
          title: map['title']?.toString() ?? 'Episode',
          season: seasonNum,
          episodeNumber: int.tryParse(map['episode_num']?.toString() ?? '') ?? 0,
          streamUrl: buildStreamUrl(StreamType.series, episodeId, map['container_extension']),
        );
      }).toList()
        ..sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
      seasons[seasonNum] = episodes;
    });

    return (details: details, seasons: seasons);
  }

  MediaDetails _mediaDetailsFromInfo(Map<String, dynamic> info) {
    return MediaDetails(
      plot: info['plot']?.toString(),
      cast: info['cast']?.toString(),
      director: info['director']?.toString(),
      releaseDate: (info['releasedate'] ?? info['release_date'])?.toString(),
      rating: info['rating']?.toString(),
      genre: info['genre']?.toString(),
    );
  }

  /// Holt den EPG (Programmfuehrer) fuer einen Sender der naechsten Stunden.
  Future<List<dynamic>> getShortEpg(String streamId) async {
    final res = await http
        .get(_apiUri('get_short_epg', {'stream_id': streamId}))
        .timeout(const Duration(seconds: 15));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['epg_listings'] as List<dynamic>? ?? [];
  }

  /// Wie [getShortEpg], aber bereits in nutzbare [EpgProgram]-Objekte
  /// umgewandelt (Titel/Beschreibung sind bei Xtream ueblicherweise
  /// Base64-kodiert).
  Future<List<EpgProgram>> getEpgPrograms(String streamId) async {
    final listings = await getShortEpg(streamId);
    return listings.map((raw) {
      final entry = raw as Map<String, dynamic>;
      final startTs = int.tryParse(entry['start_timestamp']?.toString() ?? '');
      final stopTs = int.tryParse(entry['stop_timestamp']?.toString() ?? '');
      return EpgProgram(
        title: _decodeMaybeBase64(entry['title']) ?? 'Unbekannt',
        description: _decodeMaybeBase64(entry['description']),
        start: startTs != null
            ? DateTime.fromMillisecondsSinceEpoch(startTs * 1000)
            : DateTime.tryParse(entry['start']?.toString() ?? '') ?? DateTime.now(),
        end: stopTs != null
            ? DateTime.fromMillisecondsSinceEpoch(stopTs * 1000)
            : DateTime.tryParse(entry['end']?.toString() ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  String? _decodeMaybeBase64(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    if (text.isEmpty) return null;
    try {
      return utf8.decode(base64.decode(text));
    } catch (_) {
      // Manche Server liefern Klartext statt Base64 - dann einfach uebernehmen.
      return text;
    }
  }
}
