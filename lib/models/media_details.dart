/// Zusatzinformationen zu einem Film oder einer Serie (Beschreibung,
/// Besetzung, etc.), wie sie Xtream ueber get_vod_info/get_series_info
/// liefert. Fuer M3U-Quellen nicht verfuegbar.
class MediaDetails {
  final String? plot;
  final String? cast;
  final String? director;
  final String? releaseDate;
  final String? rating;
  final String? genre;

  MediaDetails({this.plot, this.cast, this.director, this.releaseDate, this.rating, this.genre});
}
