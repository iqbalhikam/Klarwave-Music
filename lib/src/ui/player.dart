import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../player/controller.dart';
import '../providers.dart';
import '../services/store.dart';
import 'kit.dart';
import 'lyrics.dart';
import 'sheets.dart';

void openPlayer(BuildContext context) {
  Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) => const PlayerPage(),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

class PlayerPage extends ConsumerStatefulWidget {
  const PlayerPage({super.key});

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  bool _showLyrics = false;
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final store = ref.watch(storeProvider);
    final track = player.current;

    if (track == null) {
      return const Scaffold(backgroundColor: kBg);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (track.artwork != null)
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: CachedNetworkImage(
                imageUrl: track.artwork!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    const ColoredBox(color: Color(0xFF0B0A18)),
              ),
            )
          else
            const ColoredBox(color: Color(0xFF0B0A18)),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCC05060A),
                  Color(0xF205060A),
                  Color(0xFF05060A),
                ],
                stops: [0, 0.6, 1],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _topBar(context, player, track),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _showLyrics
                        ? LyricsPanel(
                            key: ValueKey('lyrics-${track.key}'),
                            track: track,
                          )
                        : _cover(track, store),
                  ),
                ),
                if (player.error != null) _errorRow(player),
                _seekRow(player, track),
                const SizedBox(height: 4),
                _controls(player),
                const SizedBox(height: 10),
                _secondaryRow(player),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(
    BuildContext context,
    PlayerController player,
    Track track,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Row(
        children: [
          IconCircle(
            icon: Icons.keyboard_arrow_down_rounded,
            size: 40,
            onTap: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'SEDANG DIPUTAR',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                    color: Colors.white38,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  track.isLive
                      ? 'Radio langsung'
                      : (track.album ?? track.source.toUpperCase()),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                ),
              ],
            ),
          ),
          IconCircle(
            icon: Icons.queue_music_rounded,
            size: 40,
            onTap: () => showQueueSheet(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _cover(Track track, AppStore store) {
    final liked = store.isLiked(track);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 6, 28, 2),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 360,
                  maxHeight: 360,
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 48,
                          offset: const Offset(0, 26),
                        ),
                      ],
                    ),
                    child: CoverArt(
                      url: track.artwork,
                      seed: track.title,
                      radius: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: kMuted),
                    ),
                  ],
                ),
              ),
              IconCircle(
                icon: liked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 46,
                active: liked,
                onTap: () => store.toggleLike(track),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _errorRow(PlayerController player) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 15, color: Color(0xFFFF8098)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              player.error!,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFFFF8098)),
            ),
          ),
          TextButton(
            onPressed: player.retry,
            child: const Text('Coba lagi', style: TextStyle(fontSize: 11.5)),
          ),
        ],
      ),
    );
  }

  Widget _seekRow(PlayerController player, Track track) {
    if (track.isLive) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(28, 10, 28, 8),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFF4D6D),
              ),
            ),
            const SizedBox(width: 7),
            const Text(
              'SIARAN LANGSUNG',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: Color(0xFFFF8098),
              ),
            ),
            const Spacer(),
            const Icon(Icons.radio_rounded, size: 14, color: Colors.white38),
            const SizedBox(width: 5),
            const Text(
              'Radio Browser',
              style: TextStyle(fontSize: 10.5, color: Colors.white38),
            ),
          ],
        ),
      );
    }

    final total = player.duration ?? track.duration;
    final max = (total?.inMilliseconds ?? 0).toDouble();
    final hasDuration = max > 0;
    final position = (_drag ?? player.position.inMilliseconds.toDouble())
        .clamp(0.0, hasDuration ? max : 0.0)
        .toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: Colors.white.withOpacity(0.12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: hasDuration ? position : 0,
              max: hasDuration ? max : 1,
              onChanged: hasDuration
                  ? (value) => setState(() => _drag = value)
                  : null,
              onChangeEnd: hasDuration
                  ? (value) {
                      player.seek(
                        Duration(milliseconds: value.round()),
                      );
                      setState(() => _drag = null);
                    }
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Text(
                  fmtDur(Duration(milliseconds: position.round())),
                  style: const TextStyle(fontSize: 10.5, color: Colors.white38),
                ),
                const Spacer(),
                Text(
                  hasDuration ? fmtDur(total) : '--:--',
                  style: const TextStyle(fontSize: 10.5, color: Colors.white38),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls(PlayerController player) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconCircle(
            icon: Icons.shuffle_rounded,
            size: 44,
            active: player.shuffle,
            onTap: player.toggleShuffle,
          ),
          IconCircle(
            icon: Icons.skip_previous_rounded,
            size: 52,
            onTap: player.previous,
          ),
          PlayButton(
            playing: player.playing,
            busy: player.loading,
            size: 78,
            onTap: player.toggle,
          ),
          IconCircle(
            icon: Icons.skip_next_rounded,
            size: 52,
            onTap: player.next,
          ),
          IconCircle(
            icon: player.repeatOne
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            size: 44,
            active: player.repeatOne || player.repeatAll,
            onTap: player.toggleRepeat,
          ),
        ],
      ),
    );
  }

  Widget _secondaryRow(PlayerController player) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: GlassPanel(
              radius: 18,
              padding: const EdgeInsets.symmetric(vertical: 11),
              opacity: _showLyrics ? 0.16 : 0.07,
              borderOpacity: _showLyrics ? 0.3 : 0.12,
              onTap: () => setState(() => _showLyrics = !_showLyrics),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.subject_rounded,
                    size: 16,
                    color: _showLyrics ? kAccentB : Colors.white60,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Lirik',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _showLyrics ? Colors.white : Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GlassPanel(
              radius: 18,
              padding: const EdgeInsets.symmetric(vertical: 11),
              opacity: player.sleepRemaining != null ? 0.16 : 0.07,
              borderOpacity: player.sleepRemaining != null ? 0.3 : 0.12,
              onTap: () => showSleepTimerSheet(context, ref),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: player.sleepRemaining != null
                        ? kAccentB
                        : Colors.white60,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    player.sleepRemaining != null
                        ? fmtDur(player.sleepRemaining)
                        : 'Timer tidur',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: player.sleepRemaining != null
                          ? Colors.white
                          : Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
