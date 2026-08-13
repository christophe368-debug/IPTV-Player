import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/channel.dart';

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
      return Channel(
        id: streamId,
        name: e['name'] as String? ?? '?',
        categoryId: (e['category_id'] ?? '').toString(),
        logoUrl: e['stream_icon'] as String? ?? e['cover'] as String?,
        streamUrl: type == StreamType.series ? '' : buildStreamUrl(type, streamId, e['container_extension']),
        streamType: type,
        epgChannelId: e['epg_channel_id'] as String?,
      );
    }).toList();
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

  /// Holt den EPG (Programmfuehrer) fuer einen Sender der naechsten Tage.
  Future<List<dynamic>> getShortEpg(String streamId) async {
    final res = await http
        .get(_apiUri('get_short_epg', {'stream_id': streamId}))
        .timeout(const Duration(seconds: 15));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['epg_listings'] as List<dynamic>? ?? [];
  }
}
