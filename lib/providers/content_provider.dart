import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../models/channel.dart';
import '../models/episode.dart';
import '../models/epg_program.dart';
import '../models/media_details.dart';
import '../models/profile.dart';
import '../repositories/content_repository.dart';
import '../services/xtream_service.dart';

/// Fuer Xtream-spezifische Detailinfos (VOD-Beschreibung, Serien-Episoden),
/// die es in der M3U-Welt nicht gibt - deshalb ausserhalb der generischen
/// ContentRepository-Abstraktion. Diese Provider werden nur von Screens
/// genutzt, die vorher sichergestellt haben, dass profile.type == xtream ist.
final xtreamServiceProvider = Provider.family<XtreamService, Profile>((ref, profile) {
  return XtreamService(
    serverUrl: profile.serverUrl!,
    username: profile.username!,
    password: profile.password!,
  );
});

final vodDetailsProvider = FutureProvider.family<MediaDetails, ({Profile profile, String vodId})>((ref, q) {
  return ref.watch(xtreamServiceProvider(q.profile)).getVodInfo(q.vodId);
});

final seriesDetailsProvider = FutureProvider.family<
    ({MediaDetails details, Map<int, List<Episode>> seasons}),
    ({Profile profile, String seriesId})>((ref, q) {
  return ref.watch(xtreamServiceProvider(q.profile)).getSeriesDetails(q.seriesId);
});

/// Erstellt das passende ContentRepository fuer ein Profil (Xtream oder M3U).
final contentRepositoryProvider = Provider.family<ContentRepository, Profile>((ref, profile) {
  switch (profile.type) {
    case ProfileType.xtream:
      return XtreamContentRepository(XtreamService(
        serverUrl: profile.serverUrl!,
        username: profile.username!,
        password: profile.password!,
      ));
    case ProfileType.m3uUrl:
      return M3uContentRepository(source: profile.m3uSource!, isLocalFile: false);
    case ProfileType.m3uFile:
      return M3uContentRepository(source: profile.m3uSource!, isLocalFile: true);
  }
});

/// Kategorien fuer einen bestimmten Inhaltstyp (Live/VOD/Serien) im
/// aktiven Profil.
typedef CategoriesQuery = ({Profile profile, StreamType type});

final categoriesProvider = FutureProvider.family<List<Category>, CategoriesQuery>((ref, query) {
  return ref.watch(contentRepositoryProvider(query.profile)).getCategories(query.type);
});

/// Sender/Filme/Serien innerhalb einer Kategorie (oder aller Kategorien,
/// wenn categoryId null ist).
typedef ChannelsQuery = ({Profile profile, StreamType type, String? categoryId});

final channelsProvider = FutureProvider.family<List<Channel>, ChannelsQuery>((ref, query) {
  return ref
      .watch(contentRepositoryProvider(query.profile))
      .getChannels(query.type, categoryId: query.categoryId);
});

typedef EpgQuery = ({Profile profile, Channel channel});

final epgProvider = FutureProvider.family<List<EpgProgram>, EpgQuery>((ref, query) {
  return ref.watch(contentRepositoryProvider(query.profile)).getEpg(query.channel);
});
