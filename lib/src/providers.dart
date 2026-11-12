import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'player/controller.dart';
import 'services/aggregator.dart';
import 'services/archive_api.dart';
import 'services/audius_api.dart';
import 'services/ccmixter_api.dart';
import 'services/lyrics_api.dart';
import 'services/openverse_api.dart';
import 'services/radio_api.dart';
import 'services/store.dart';

final audiusProvider = Provider<AudiusApi>((ref) => AudiusApi());
final archiveProvider = Provider<ArchiveApi>((ref) => ArchiveApi());
final openverseProvider = Provider<OpenverseApi>((ref) => OpenverseApi());
final ccmixterProvider = Provider<CcMixterApi>((ref) => CcMixterApi());
final radioProvider = Provider<RadioApi>((ref) => RadioApi());
final lyricsProvider = Provider<LyricsApi>((ref) => LyricsApi());

final aggregatorProvider = Provider<MusicAggregator>(
  (ref) => MusicAggregator(
    audius: ref.read(audiusProvider),
    archive: ref.read(archiveProvider),
    openverse: ref.read(openverseProvider),
    ccmixter: ref.read(ccmixterProvider),
  ),
);

final storeProvider = ChangeNotifierProvider<AppStore>(
  (ref) => AppStore.instance,
);

final playerProvider = ChangeNotifierProvider<PlayerController>(
  (ref) => PlayerController(
    store: ref.read(storeProvider),
    audius: ref.read(audiusProvider),
  ),
);
