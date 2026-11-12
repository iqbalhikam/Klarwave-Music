import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'kit.dart';

Future<void> showTrackMenu(
  BuildContext context,
  WidgetRef ref,
  Track track, {
  String? playlist,
}) async {
  final store = ref.read(storeProvider);
  final liked = store.isLiked(track);

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: GlassPanel(
        radius: 30,
        opacity: 0.16,
        blur: 36,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CoverArt(url: track.artwork, seed: track.title, size: 54),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: kMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SheetAction(
              icon: liked
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              label: liked ? 'Hapus dari disukai' : 'Simpan ke disukai',
              onTap: () {
                store.toggleLike(track);
                Navigator.of(sheetContext).pop();
              },
            ),
            _SheetAction(
              icon: Icons.playlist_add_rounded,
              label: 'Tambahkan ke playlist',
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await _pickPlaylist(context, ref, track);
              },
            ),
            if (playlist != null)
              _SheetAction(
                icon: Icons.remove_circle_outline_rounded,
                label: 'Hapus dari "$playlist"',
                onTap: () {
                  store.removeFromPlaylist(playlist, track);
                  Navigator.of(sheetContext).pop();
                },
              ),
            _SheetAction(
              icon: Icons.play_arrow_rounded,
              label: 'Putar sekarang',
              onTap: () {
                ref.read(playerProvider).playTrack(track);
                Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _pickPlaylist(
  BuildContext context,
  WidgetRef ref,
  Track track,
) async {
  final store = ref.read(storeProvider);
  final names = store.playlistNames;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: GlassPanel(
        radius: 30,
        opacity: 0.16,
        blur: 36,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Simpan ke playlist',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            for (final name in names)
              _SheetAction(
                icon: Icons.queue_music_rounded,
                label: name,
                onTap: () {
                  store.addToPlaylist(name, track);
                  Navigator.of(sheetContext).pop();
                },
              ),
            _SheetAction(
              icon: Icons.add_rounded,
              label: 'Buat playlist baru',
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final name = await showCreatePlaylistDialog(context);
                if (name != null) store.addToPlaylist(name, track);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Future<String?> showCreatePlaylistDialog(BuildContext context) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: const Color(0xFF14121F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Playlist baru'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 40,
        decoration: const InputDecoration(
          hintText: 'Nama playlist',
          counterText: '',
        ),
        onSubmitted: (value) =>
            Navigator.of(dialogContext).pop(value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(controller.text.trim()),
          child: const Text('Buat'),
        ),
      ],
    ),
  );
}

Future<void> showSleepTimerSheet(BuildContext context, WidgetRef ref) async {
  final player = ref.read(playerProvider);
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: GlassPanel(
        radius: 30,
        opacity: 0.16,
        blur: 36,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                'Timer tidur',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            for (final minutes in [10, 20, 30, 45, 60])
              _SheetAction(
                icon: Icons.timer_outlined,
                label: '$minutes menit',
                onTap: () {
                  player.startSleepTimer(Duration(minutes: minutes));
                  Navigator.of(sheetContext).pop();
                },
              ),
            if (player.sleepRemaining != null)
              _SheetAction(
                icon: Icons.close_rounded,
                label: 'Matikan timer',
                onTap: () {
                  player.cancelSleepTimer();
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showQueueSheet(BuildContext context, WidgetRef ref) async {
  final player = ref.read(playerProvider);
  final queue = player.queue;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
      child: GlassPanel(
        radius: 30,
        opacity: 0.16,
        blur: 36,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Text(
                    'Antrean',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    '${queue.length} lagu',
                    style: const TextStyle(fontSize: 12, color: kMuted),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: queue.length,
                itemBuilder: (context, i) {
                  final track = queue[i];
                  final active = i == player.index;
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      player.jumpTo(i);
                      Navigator.of(sheetContext).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          CoverArt(
                            url: track.artwork,
                            seed: track.title,
                            size: 42,
                            radius: 11,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: active ? kAccentB : Colors.white,
                                  ),
                                ),
                                Text(
                                  track.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: kMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (active)
                            const Icon(
                              Icons.graphic_eq_rounded,
                              size: 18,
                              color: kAccentB,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.white70),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
