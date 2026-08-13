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
}
