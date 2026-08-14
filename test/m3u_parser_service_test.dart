import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_player/models/channel.dart';
import 'package:iptv_player/services/m3u_parser_service.dart';

void main() {
  final parser = M3uParserService();

  test('parst Sender, Gruppen und Logos aus einer einfachen Playlist', () {
    const content = '''
#EXTM3U
#EXTINF:-1 tvg-id="ard.de" tvg-logo="http://example.com/ard.png" group-title="Oeffentlich-Rechtlich",Das Erste HD
http://example.com/stream1.m3u8
#EXTINF:-1 tvg-id="zdf.de" group-title="Oeffentlich-Rechtlich",ZDF HD
http://example.com/stream2.m3u8
#EXTINF:-1 group-title="Sport",Sky Sport 1
http://example.com/stream3.m3u8
''';

    final result = parser.parseContent(content);

    expect(result.channels, hasLength(3));
    expect(result.categories.map((c) => c.name), containsAll(['Oeffentlich-Rechtlich', 'Sport']));

    final ard = result.channels.firstWhere((c) => c.name == 'Das Erste HD');
    expect(ard.epgChannelId, 'ard.de');
    expect(ard.logoUrl, 'http://example.com/ard.png');
    expect(ard.streamUrl, 'http://example.com/stream1.m3u8');
    expect(ard.streamType, StreamType.live);
  });

  test('Sender ohne group-title landen in "Ohne Kategorie"', () {
    const content = '''
#EXTM3U
#EXTINF:-1,Test Sender
http://example.com/stream.m3u8
''';

    final result = parser.parseContent(content);
    expect(result.channels.single.categoryId, 'Ohne Kategorie');
  });

  test('liest url-tvg aus dem #EXTM3U-Header fuer EPG', () {
    const content = '''
#EXTM3U url-tvg="http://example.com/epg.xml.gz"
#EXTINF:-1,Test
http://example.com/stream.m3u8
''';

    final result = parser.parseContent(content);
    expect(result.epgUrl, 'http://example.com/epg.xml.gz');
  });

  test('leere/kaputte Playlist liefert eine leere Liste statt eines Fehlers', () {
    final result = parser.parseContent('#EXTM3U\n');
    expect(result.channels, isEmpty);
  });
}
