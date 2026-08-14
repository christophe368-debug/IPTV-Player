/// Eine einzelne Episode innerhalb einer Serien-Staffel.
class Episode {
  final String id;
  final String title;
  final int season;
  final int episodeNumber;
  final String streamUrl;

  Episode({
    required this.id,
    required this.title,
    required this.season,
    required this.episodeNumber,
    required this.streamUrl,
  });
}
