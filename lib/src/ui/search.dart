import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import '../services/store.dart';
import 'kit.dart';
import 'sheets.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  Future<List<Track>>? _results;
  String _mode = 'lagu';

  static const _genres = [
    'Pop',
    'Hip-Hop',
    'Electronic',
    'Lo-Fi',
    'Rock',
    'R&B',
    'Jazz',
    'Chill',
    'House',
    'Reggae',
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 420), () {
      _run(value);
    });
  }

  void _run(String value) {
    final query = value.trim();
    if (query.isEmpty) {
      setState(() => _results = null);
      return;
    }
    setState(() {
      _results = _mode == 'lagu'
          ? ref.read(audiusProvider).searchTracks(query)
          : ref.read(radioProvider).stations(query: query);
    });
  }

  void _setMode(String mode) {
    if (mode == _mode) return;
    setState(() => _mode = mode);
    _run(_controller.text);
  }

  void _useGenre(String genre) {
    _controller.text = genre;
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
    _run(genre);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cari',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 14),
              GlassPanel(
                radius: 20,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                opacity: 0.1,
                child: TextField(
                  controller: _controller,
                  onChanged: _onChanged,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(fontSize: 14.5),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: _mode == 'lagu'
                        ? 'Judul lagu atau nama artis'
                        : 'Nama stasiun radio',
                    hintStyle: const TextStyle(color: Colors.white38),
                    icon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white54,
                      size: 21,
                    ),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _controller.clear();
                              setState(() => _results = null);
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Colors.white54,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  GlassChip(
                    label: 'Lagu',
                    icon: Icons.music_note_rounded,
                    selected: _mode == 'lagu',
                    onTap: () => _setMode('lagu'),
                  ),
                  const SizedBox(width: 8),
                  GlassChip(
                    label: 'Radio',
                    icon: Icons.radio_rounded,
                    selected: _mode == 'radio',
                    onTap: () => _setMode('radio'),
                  ),
                  const Spacer(),
                  Text(
                    _mode == 'lagu' ? 'Audius' : 'Radio Browser',
                    style: const TextStyle(fontSize: 10.5, color: Colors.white30),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
        Expanded(child: _body(store)),
      ],
    );
  }

  Widget _body(AppStore store) {
    final future = _results;
    if (future == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 200),
        children: [
          const Text(
            'Jelajahi genre',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final genre in _genres)
                GlassChip(label: genre, onTap: () => _useGenre(genre)),
            ],
          ),
          const SizedBox(height: 24),
          EmptyState(
            icon: _mode == 'lagu'
                ? Icons.headphones_rounded
                : Icons.radio_rounded,
            title: _mode == 'lagu'
                ? 'Temukan lagu berikutnya'
                : 'Dengarkan radio dunia',
            message: _mode == 'lagu'
                ? 'Ketik judul atau artis. Katalog musik gratis dari Audius siap diputar.'
                : 'Ketik nama stasiun, atau ketuk genre di atas untuk mencari stasiun dengan tag tersebut.',
          ),
        ],
      );
    }

    return FutureBuilder<List<Track>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 200),
            children: [
              ErrorPanel(onRetry: () => _run(_controller.text)),
            ],
          );
        }
        final tracks = snapshot.data;
        if (tracks == null) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: LoadingRows(count: 5),
          );
        }
        if (tracks.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 200),
            children: const [
              EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Tidak ditemukan',
                message: 'Coba kata kunci lain, atau cari dalam mode radio.',
              ),
            ],
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 200),
          itemCount: tracks.length,
          itemBuilder: (context, i) {
            final track = tracks[i];
            return TrackTile(
              track: track,
              liked: store.isLiked(track),
              subtitle: track.isLive ? track.artist : null,
              onTap: () => _play(tracks, i),
              onLike: () => store.toggleLike(track),
              onMore: () => showTrackMenu(context, ref, track),
            );
          },
        );
      },
    );
  }
}
