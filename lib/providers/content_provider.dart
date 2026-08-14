import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../models/channel.dart';
import '../models/epg_program.dart';
import '../models/profile.dart';
import '../repositories/content_repository.dart';
import '../services/xtream_service.dart';

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

final liveCategoriesProvider = FutureProvider.family<List<Category>, Profile>((ref, profile) {
  return ref.watch(contentRepositoryProvider(profile)).getCategories(StreamType.live);
});

typedef ChannelsQuery = ({Profile profile, String? categoryId});

final liveChannelsProvider = FutureProvider.family<List<Channel>, ChannelsQuery>((ref, query) {
  return ref
      .watch(contentRepositoryProvider(query.profile))
      .getChannels(StreamType.live, categoryId: query.categoryId);
});

typedef EpgQuery = ({Profile profile, Channel channel});

final epgProvider = FutureProvider.family<List<EpgProgram>, EpgQuery>((ref, query) {
  return ref.watch(contentRepositoryProvider(query.profile)).getEpg(query.channel);
});
