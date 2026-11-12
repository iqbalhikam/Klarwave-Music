import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';

const kBg = Color(0xFF06070C);
const kMuted = Color(0xFF98A1B6);
const kAccentA = Color(0xFF8A7CFF);
const kAccentB = Color(0xFF4FE3C1);
const kGradient = LinearGradient(
  colors: [kAccentA, kAccentB],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

String fmtDur(Duration? value) {
  if (value == null) return '--:--';
  final hours = value.inHours;
  final minutes = value.inMinutes.remainder(60);
  final seconds = value.inSeconds.remainder(60);
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$mm:$ss' : '$minutes:$ss';
}

class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0A14), Color(0xFF0C0918), Color(0xFF050A0E)],
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _AuroraPainter(_controller.value * 2 * math.pi),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.phase);

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide;

    void blob(Offset center, double r, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, color.withOpacity(0)],
        ).createShader(Rect.fromCircle(center: center, radius: r));
      canvas.drawCircle(center, r, paint);
    }

    blob(
      Offset(
        size.width * (0.18 + 0.08 * math.sin(phase)),
        size.height * (0.12 + 0.03 * math.cos(phase * 0.8)),
      ),
      radius * 0.95,
      const Color(0xFF6D5BFF).withOpacity(0.55),
    );
    blob(
      Offset(
        size.width * (0.95 + 0.05 * math.cos(phase * 1.2)),
        size.height * (0.38 + 0.05 * math.sin(phase)),
      ),
      radius * 0.8,
      const Color(0xFF1ED9B7).withOpacity(0.32),
    );
    blob(
      Offset(
        size.width * (0.5 + 0.12 * math.cos(phase * 0.7)),
        size.height * (0.98 + 0.02 * math.sin(phase * 1.4)),
      ),
      radius * 0.9,
      const Color(0xFFC04BFF).withOpacity(0.22),
    );
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 26,
    this.blur = 24,
    this.opacity = 0.10,
    this.borderOpacity = 0.18,
    this.color,
    this.onTap,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double blur;
  final double opacity;
  final double borderOpacity;
  final Color? color;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Colors.white;
    final panel = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tint.withOpacity(opacity),
            tint.withOpacity(opacity * 0.3),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(borderOpacity),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );

    final glass = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: panel,
      ),
    );

    if (onTap == null) return glass;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: glass,
    );
  }
}

class CoverArt extends StatelessWidget {
  const CoverArt({
    super.key,
    required this.url,
    required this.seed,
    this.size,
    this.radius = 14,
  });

  final String? url;
  final String seed;
  final double? size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final placeholder = _CoverPlaceholder(seed: seed);
    final image = (url == null || url!.isEmpty)
        ? placeholder
        : CachedNetworkImage(
            imageUrl: url!,
            fit: BoxFit.cover,
            width: size,
            height: size,
            memCacheWidth: size == null ? 720 : (size! * 2).round(),
            placeholder: (_, __) => placeholder,
            errorWidget: (_, __, ___) => placeholder,
          );

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: image,
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({required this.seed});

  final String seed;

  @override
  Widget build(BuildContext context) {
    final hue = (seed.hashCode.abs() % 360).toDouble();
    final start = HSLColor.fromAHSL(1, hue, 0.55, 0.34).toColor();
    final end = HSLColor.fromAHSL(1, (hue + 48) % 360, 0.6, 0.22).toColor();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [start, end],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.music_note_rounded, color: Colors.white38, size: 28),
      ),
    );
  }
}

class IconCircle extends StatelessWidget {
  const IconCircle({
    super.key,
    required this.icon,
    this.size = 44,
    this.iconSize,
    this.onTap,
    this.active = false,
  });

  final IconData icon;
  final double size;
  final double? iconSize;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? kAccentA.withOpacity(0.24)
              : Colors.white.withOpacity(0.08),
          border: Border.all(
            color: Colors.white.withOpacity(active ? 0.38 : 0.14),
          ),
        ),
        child: Icon(
          icon,
          size: iconSize ?? size * 0.46,
          color: Colors.white.withOpacity(active ? 1 : 0.92),
        ),
      ),
    );
  }
}

class PlayButton extends StatelessWidget {
  const PlayButton({
    super.key,
    required this.playing,
    required this.onTap,
    this.busy = false,
    this.size = 76,
  });

  final bool playing;
  final bool busy;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: kGradient,
          boxShadow: [
            BoxShadow(
              color: kAccentA.withOpacity(0.45),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: busy
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Color(0xFF0A0A12),
                  ),
                ),
              )
            : Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: size * 0.52,
                color: const Color(0xFF0A0A12),
              ),
      ),
    );
  }
}

class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: selected ? kGradient : null,
          color: selected ? null : Colors.white.withOpacity(0.07),
          border: Border.all(
            color: Colors.white.withOpacity(selected ? 0.25 : 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: selected ? const Color(0xFF0A0A12) : Colors.white70,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? const Color(0xFF0A0A12) : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class CoverCard extends StatelessWidget {
  const CoverCard({
    super.key,
    required this.track,
    this.onTap,
    required this.width,
    this.round = 18,
    this.showArtist = true,
  });

  final Track track;
  final VoidCallback? onTap;
  final double width;
  final double round;
  final bool showArtist;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CoverArt(url: track.artwork, seed: track.title, size: width, radius: round),
            const SizedBox(height: 8),
            Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            if (showArtist) ...[
              const SizedBox(height: 2),
              Text(
                track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, color: kMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.track,
    this.onTap,
    this.onLike,
    this.onMore,
    this.liked = false,
    this.subtitle,
    this.trailing,
  });

  final Track track;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onMore;
  final bool liked;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                CoverArt(url: track.artwork, seed: track.title, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle ?? track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: kMuted),
                      ),
                    ],
                  ),
                ),
                if (track.isLive)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D6D).withOpacity(0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFFFF4D6D).withOpacity(0.4),
                      ),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: Color(0xFFFF8098),
                      ),
                    ),
                  ),
                if (trailing != null) trailing!,
                if (onLike != null)
                  IconButton(
                    onPressed: onLike,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 20,
                      color: liked ? const Color(0xFFFF7EA8) : Colors.white54,
                    ),
                  ),
                if (onMore != null)
                  IconButton(
                    onPressed: onMore,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      size: 21,
                      color: Colors.white54,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GlassNav extends StatelessWidget {
  const GlassNav({
    super.key,
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = <(IconData, String)>[
    (Icons.home_rounded, 'Beranda'),
    (Icons.search_rounded, 'Cari'),
    (Icons.library_music_rounded, 'Koleksi'),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 28,
      padding: const EdgeInsets.all(6),
      opacity: 0.13,
      borderOpacity: 0.2,
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: index == i ? kGradient : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _items[i].$1,
                        size: 22,
                        color: index == i
                            ? const Color(0xFF0A0A12)
                            : Colors.white60,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _items[i].$2,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                          color: index == i
                              ? const Color(0xFF0A0A12)
                              : Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final track = player.current;
    if (track == null) return const SizedBox.shrink();

    final total = player.duration ?? track.duration;
    final value = (track.isLive || total == null || total.inMilliseconds == 0)
        ? 0.0
        : (player.position.inMilliseconds / total.inMilliseconds)
            .clamp(0.0, 1.0)
            .toDouble();

    return GlassPanel(
      radius: 26,
      padding: EdgeInsets.zero,
      opacity: 0.16,
      blur: 30,
      onTap: onOpen,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                CoverArt(
                  url: track.artwork,
                  seed: track.title,
                  size: 42,
                  radius: 12,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: kMuted),
                      ),
                    ],
                  ),
                ),
                IconCircle(
                  icon: player.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 40,
                  onTap: player.toggle,
                ),
                const SizedBox(width: 6),
                IconCircle(
                  icon: Icons.skip_next_rounded,
                  size: 40,
                  onTap: player.next,
                ),
                const SizedBox(width: 2),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(26),
            ),
            child: LinearProgressIndicator(
              value: track.isLive ? null : value,
              minHeight: 2.5,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: const AlwaysStoppedAnimation(kAccentB),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 34, color: Colors.white54),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: kMuted, height: 1.45),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'Gagal memuat musik',
      message:
          'Periksa koneksi internet lalu coba lagi. Katalog Audius kadang lambat merespons.',
      action: TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Coba lagi'),
      ),
    );
  }
}

class LoadingRows extends StatelessWidget {
  const LoadingRows({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(0.04),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
          ),
      ],
    );
  }
}
