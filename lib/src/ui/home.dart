import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'collection.dart';
import 'kit.dart';
import 'sheets.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _time = 'week';
  late Future<List<Track>> _trending;
  late Future<List<Track>> _radios;
  late Future<List<Track>> _archive;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _trending = ref.read(audiusProvider).trending(time: _time, limit: 24);
    _radios = ref.read(radioProvider).stations(
          limit: 12,
          countryCode: 'ID',
        );
    _archive = ref.read(archiveProvider).indonesian(limit: 10);
  }

  Future<void> _refresh() async {
    setState(_reload);
    try {
      await Future.wait([_trending, _radios, _archive]);
    } catch (_) {}
  }

  void _play(List<Track> tracks, int index) {
    ref.read(playerProvider).playTrack(
          tracks[index],
          queue: tracks,
          index: index,
        );
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider);
    final recents = store.recent;

    return RefreshIndicator(
      color: kAccentA,
      backgroundColor: const Color(0xFF141422),
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 200),
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: kGradient,
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: Color(0xFF0A0A12),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Klarwave Music',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  Text(
                    'Musik gratis, tanpa iklan.',
                    style: TextStyle(fontSize: 11.5, color: kMuted),
                  ),
                ],
              ),
              const Spacer(),
              IconCircle(
                icon: Icons.refresh_rounded,
                size: 40,
                onTap: _refresh,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            children: [
              GlassChip(
                label: 'Minggu ini',
                selected: _time == 'week',
                onTap: () => _selectTime('week'),
              ),
              GlassChip(
                label: 'Bulan ini',
                selected: _time == 'month',
                onTap: () => _selectTime('month'),
              ),
              GlassChip(
                label: 'Sepanjang masa',
                selected: _time == 'allTime',
                onTap: () => _selectTime('allTime'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<Track>>(
            future: _trending,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ErrorPanel(onRetry: () => setState(_reload));
              }
              final tracks = snapshot.data;
              if (tracks == null) return const LoadingRows(count: 3);
              if (tracks.isEmpty) {
                return const EmptyState(
                  icon: Icons.music_off_rounded,
                  title: 'Belum ada lagu',
                  message: 'Coba segarkan halaman ini beberapa saat lagi.',
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Featured(track: tracks.first, onTap: () => _play(tracks, 0)),
                  const SizedBox(height: 20),
                  const SectionTitle('Sedang populer'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 178,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: tracks.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => CoverCard(
                        track: tracks[i],
                        width: 128,
                        onTap: () => _play(tracks, i),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 26),
          const SectionTitle(
            'Arsip Indonesia',
            trailing: Text(
              'Domain publik & CC',
              style: TextStyle(fontSize: 10.5, color: Colors.white38),
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Track>>(
            future: _archive,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const EmptyState(
                  icon: Icons.library_music_rounded,
                  title: 'Arsip tidak tersedia',
                  message: 'Internet Archive sedang tidak dapat dihubungi.',
                );
              }
              final tracks = snapshot.data;
              if (tracks == null) return const LoadingRows(count: 2);
              if (tracks.isEmpty) {
                return const EmptyState(
                  icon: Icons.library_music_rounded,
                  title: 'Belum ada arsip',
                  message: 'Coba cari lewat halaman Cari dengan filter Arsip.',
                );
              }
              return SizedBox(
                height: 178,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: tracks.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => CoverCard(
                    track: tracks[i],
                    width: 128,
                    onTap: () => _play(tracks, i),
                  ),
                ),
              );
            },
          ),
          if (recents.isNotEmpty) ...[
            const SizedBox(height: 26),
            SectionTitle(
              'Terakhir diputar',
              trailing: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TrackListPage(
                      title: 'Terakhir diputar',
                      tracks: recents,
                    ),
                  ),
                ),
                child: const Text(
                  'Lihat semua',
                  style: TextStyle(fontSize: 12, color: kAccentB),
                ),
              ),
            ),
            const SizedBox(height: 6),
            for (var i = 0; i < recents.length && i < 4; i++)
              TrackTile(
                track: recents[i],
                liked: store.isLiked(recents[i]),
                onTap: () => _play(recents, i),
                onLike: () => store.toggleLike(recents[i]),
                onMore: () => showTrackMenu(context, ref, recents[i]),
              ),
          ],
          const SizedBox(height: 26),
          const SectionTitle('Radio Indonesia'),
          const SizedBox(height: 12),
          FutureBuilder<List<Track>>(
            future: _radios,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const EmptyState(
                  icon: Icons.radio_rounded,
                  title: 'Radio tidak tersedia',
                  message: 'Server radio sedang sibuk. Coba lagi nanti.',
                );
              }
              final stations = snapshot.data;
              if (stations == null) return const LoadingRows(count: 2);
              if (stations.isEmpty) {
                return const EmptyState(
                  icon: Icons.radio_rounded,
                  title: 'Belum ada stasiun',
                  message: 'Tidak ada stasiun radio yang bisa dimuat.',
                );
              }
              return SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: stations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, i) {
                    final station = stations[i];
                    return GestureDetector(
                      onTap: () => _play(stations, i),
                      child: SizedBox(
                        width: 96,
                        child: Column(
                          children: [
                            CoverArt(
                              url: station.artwork,
                              seed: station.title,
                              size: 92,
                              radius: 46,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              station.title,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          const Center(
            child: Text(
              'Audius · Internet Archive · Openverse · ccMixter · Radio Browser',
              style: TextStyle(fontSize: 10.5, color: Colors.white38),
            ),
          ),
        ],
      ),
    );
  }

  void _selectTime(String value) {
    setState(() {
      _time = value;
      _reload();
    });
  }
}

class _Featured extends StatelessWidget {
  const _Featured({required this.track, required this.onTap});

  final Track track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 28,
      padding: const EdgeInsets.all(14),
      opacity: 0.14,
      blur: 30,
      onTap: onTap,
      child: Row(
        children: [
          CoverArt(url: track.artwork, seed: track.title, size: 98, radius: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOP TRENDING',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: kAccentB,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  track.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  track.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: kMuted),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        gradient: kGradient,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 16,
                            color: Color(0xFF0A0A12),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Putar',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0A0A12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      fmtDur(track.duration),
                      style: const TextStyle(fontSize: 11, color: kMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
