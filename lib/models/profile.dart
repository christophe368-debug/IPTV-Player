/// Ein "Profil" ist eine gespeicherte IPTV-Quelle des Nutzers:
/// entweder ein Xtream-Codes-Zugang, eine M3U-Playlist-URL oder eine
/// lokal importierte M3U-Datei. Der Nutzer kann mehrere Profile anlegen
/// und zwischen ihnen wechseln.
library;

enum ProfileType { xtream, m3uUrl, m3uFile }

class Profile {
  final String id;
  final String name;
  final ProfileType type;

  // Nur für Xtream Codes:
  final String? serverUrl;
  final String? username;
  final String? password;

  // Für M3U-URL bzw. lokale Datei:
  final String? m3uSource;

  Profile({
    required this.id,
    required this.name,
    required this.type,
    this.serverUrl,
    this.username,
    this.password,
    this.m3uSource,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'serverUrl': serverUrl,
      'username': username,
      'password': password,
      'm3uSource': m3uSource,
    };
  }

  factory Profile.fromMap(Map<dynamic, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      name: map['name'] as String,
      type: ProfileType.values.firstWhere((t) => t.name == map['type']),
      serverUrl: map['serverUrl'] as String?,
      username: map['username'] as String?,
      password: map['password'] as String?,
      m3uSource: map['m3uSource'] as String?,
    );
  }
}
