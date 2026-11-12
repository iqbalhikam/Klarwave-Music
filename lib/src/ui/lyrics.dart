import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import '../services/lyrics_api.dart';
import 'kit.dart';

class LyricsPanel extends ConsumerStatefulWidget {
  const LyricsPanel({super.key, required this.track});

  final Track track;

  @override
  ConsumerState<LyricsPanel> createState() => _LyricsPanelState();
}

class _LyricsPanelState extends ConsumerState<LyricsPanel> {
  late final Future<Lyrics?> _future;
  final ScrollController _scroll = ScrollController();
  int _active = -1;

  static const _lineHeight = 52.0;
  static const _topPad = 110.0;

  @override
  void initState() {
    super.initState();
    _future = ref.read(lyricsProvider).find(widget.track);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToActive(int index) {
    if (index < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final target = (_topPad + index * _lineHeight - 150)
          .clamp(0.0, _scroll.position.maxScrollExtent)
          .toDouble();
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 460),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Lyrics?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: kAccentB,
              ),
            ),
          );
        }

        final lyrics = snapshot.data;
        if (lyrics == null || !lyrics.hasContent) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: EmptyState(
                icon: Icons.subject_rounded,
                title: 'Lirik belum tersedia',
                message:
                    'Tidak ada lirik untuk lagu ini di LRCLIB. Coba lagu lain, atau nikmati audionya.',
              ),
            ),
          );
        }

        if (!lyrics.isSynced) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 160),
            children: [
              for (final line in lyrics.plainLines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    line,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16.5,
                      height: 1.5,
                      color: Colors.white70,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Lirik: LRCLIB (tanpa waktu)',
                  style: TextStyle(fontSize: 10.5, color: Colors.white30),
                ),
              ),
            ],
          );
        }

        final lines = lyrics.lines;
        final player = ref.read(playerProvider);

        return AnimatedBuilder(
          animation: player,
          builder: (context, _) {
            final position = player.position;
            var active = -1;
            for (var i = 0; i < lines.length; i++) {
              if (lines[i].time <= position) {
                active = i;
              } else {
                break;
              }
            }
            if (active != _active) {
              _active = active;
              _scrollToActive(active);
            }

            return ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(24, _topPad, 24, 160),
              itemExtent: _lineHeight,
              itemCount: lines.length,
              itemBuilder: (context, i) {
                final isActive = i == active;
                return Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 240),
                    style: TextStyle(
                      fontSize: isActive ? 19 : 16,
                      height: 1.3,
                      fontWeight:
                          isActive ? FontWeight.w800 : FontWeight.w500,
                      color: isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.32),
                    ),
                    child: Text(
                      lines[i].text,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
