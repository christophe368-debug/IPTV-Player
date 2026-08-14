import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_player/models/channel.dart';

void main() {
  test('Channel.toMap()/fromMap() Roundtrip erhaelt alle Felder', () {
    final original = Channel(
      id: '42',
      name: 'Test Sender',
      categoryId: 'sport',
      streamUrl: 'http://example.com/stream.ts',
      streamType: StreamType.live,
      logoUrl: 'http://example.com/logo.png',
      epgChannelId: 'test.de',
      catchupDays: 7,
    );

    final restored = Channel.fromMap(original.toMap());

    expect(restored.id, original.id);
    expect(restored.name, original.name);
    expect(restored.categoryId, original.categoryId);
    expect(restored.streamUrl, original.streamUrl);
    expect(restored.streamType, original.streamType);
    expect(restored.logoUrl, original.logoUrl);
    expect(restored.epgChannelId, original.epgChannelId);
    expect(restored.catchupDays, original.catchupDays);
    expect(restored.hasCatchup, isTrue);
  });

  test('favoriteKey unterscheidet gleiche IDs in verschiedenen Stream-Typen', () {
    final live = Channel(
      id: '1',
      name: 'A',
      categoryId: 'x',
      streamUrl: 'http://a',
      streamType: StreamType.live,
    );
    final vod = Channel(
      id: '1',
      name: 'A',
      categoryId: 'x',
      streamUrl: 'http://a',
      streamType: StreamType.vod,
    );

    // Xtream vergibt Stream-IDs pro Typ neu - ohne Namespacing wuerden ein
    // Live-Sender und ein Film mit derselben ID im Favoriten-Set kollidieren.
    expect(live.favoriteKey, isNot(equals(vod.favoriteKey)));
  });

  test('hasCatchup ist false, wenn catchupDays 0 ist (Standard)', () {
    final channel = Channel(
      id: '1',
      name: 'A',
      categoryId: 'x',
      streamUrl: 'http://a',
      streamType: StreamType.live,
    );
    expect(channel.hasCatchup, isFalse);
  });
}
