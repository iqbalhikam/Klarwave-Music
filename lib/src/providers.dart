import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'player/controller.dart';
import 'services/audius_api.dart';
import 'services/lyrics_api.dart';
import 'services/radio_api.dart';
import 'services/store.dart';

final audiusProvider = Provider<AudiusApi>((ref) => AudiusApi());
final radioProvider = Provider<RadioApi>((ref) => RadioApi());
final lyricsProvider = Provider<LyricsApi>((ref) => LyricsApi());

final storeProvider = ChangeNotifierProvider<AppStore>(
  (ref) => AppStore.instance,
);

final playerProvider = ChangeNotifierProvider<PlayerController>(
  (ref) => PlayerController(
    store: ref.read(storeProvider),
    audius: ref.read(audiusProvider),
  ),
);
