import 'channel.dart';

/// Eine Kategorie gruppiert Sender/Filme/Serien, z.B. "Sport", "Nachrichten".
class Category {
  final String id;
  final String name;
  final StreamType streamType;

  Category({
    required this.id,
    required this.name,
    required this.streamType,
  });

  Category copyWith({String? name}) {
    return Category(id: id, name: name ?? this.name, streamType: streamType);
  }
}
