/// Repraesentiert einen Sender (Live-TV), einen Film (VOD) oder eine
/// Serien-Episode. Das gleiche Modell wird fuer alle drei Typen genutzt,
/// da die Felder sich stark aehneln - `streamType` unterscheidet sie.
library;

enum StreamType { live, vod, series }

class Channel {
  final String id;
  final String name;
  final String? logoUrl;
  final String categoryId;
  final String streamUrl;
  final StreamType streamType;
  final String? epgChannelId;

  Channel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.streamUrl,
    required this.streamType,
    this.logoUrl,
    this.epgChannelId,
  });

  /// Fuer die Speicherung als Favorit (Hive kann nur einfache Typen wie
  /// Maps direkt speichern, keine eigenen Klassen).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'streamUrl': streamUrl,
      'streamType': streamType.name,
      'logoUrl': logoUrl,
      'epgChannelId': epgChannelId,
    };
  }

  factory Channel.fromMap(Map<dynamic, dynamic> map) {
    return Channel(
      id: map['id'] as String,
      name: map['name'] as String,
      categoryId: map['categoryId'] as String,
      streamUrl: map['streamUrl'] as String,
      streamType: StreamType.values.firstWhere((t) => t.name == map['streamType']),
      logoUrl: map['logoUrl'] as String?,
      epgChannelId: map['epgChannelId'] as String?,
    );
  }

  /// Eindeutiger Schluessel ueber alle Inhaltstypen hinweg - reine Sender-/
  /// Film-/Serien-IDs koennen sich zwischen Live/VOD/Serien ueberschneiden.
  String get favoriteKey => '${streamType.name}_$id';
}
