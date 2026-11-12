import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'kit.dart';
import 'sheets.dart';

class TrackListPage extends ConsumerWidget {
  const TrackListPage({
    super.key,
    required this.title,
    required this.tracks,
    this.playlist,
  });

  final String title;
  final List<Track> tracks;
  final String? playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider);
    final player = ref.read(playerProvider);

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          SafeArea(
            child: Column(
              children: [
                _CollectionHeader(
                  title: title,
                  subtitle: '${tracks.length} lagu',
                  onBack: () => Navigator.of(context).pop(),
                  onPlay: tracks.isEmpty
                      ? null
                      : () => player.playTrack(tracks.first, queue: tracks),
                ),
                Expanded(
                  child: tracks.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: EmptyState(
                            icon: Icons.playlist_remove_rounded,
                            title: 'Masih kosong',
                            message: 'Tambahkan lagu lewat menu titik tiga pada lagu mana pun.',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                          itemCount: tracks.length,
                          itemBuilder: (context, i) {
                            final track = tracks[i];
                            return TrackTile(
                              track: track,
                              liked: store.isLiked(track),
                              onTap: () => player.playTrack(
                                track,
                                queue: tracks,
                                index: i,
                              ),
                              onLike: () => store.toggleLike(track),
                              onMore: () => showTrackMenu(
                                context,
                                ref,
                                track,
                                playlist: playlist,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PlaylistPage extends ConsumerWidget {
  const PlaylistPage({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider);
    final tracks = store.playlist(name);
    final player = ref.read(playerProvider);

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          SafeArea(
            child: Column(
              children: [
                _CollectionHeader(
                  title: name,
                  subtitle: '${tracks.length} lagu',
                  onBack: () => Navigator.of(context).pop(),
                  onPlay: tracks.isEmpty
                      ? null
                      : () => player.playTrack(tracks.first, queue: tracks),
                  onDelete: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: const Color(0xFF14121F),
                        title: const Text('Hapus playlist?'),
                        content: Text(
                          'Playlist "$name" akan dihapus. Lagu di dalamnya tetap tersimpan di Disukai.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: const Text('Batal'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed ?? false) {
                      store.deletePlaylist(name);
                      if (context.mounted) Navigator.of(context).pop();
                    }
                  },
                ),
                Expanded(
                  child: tracks.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: EmptyState(
                            icon: Icons.playlist_add_rounded,
                            title: 'Playlist kosong',
                            message: 'Cari lagu, lalu pilih "Tambahkan ke playlist" dari menu lagu.',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                          itemCount: tracks.length,
                          itemBuilder: (context, i) {
                            final track = tracks[i];
                            return TrackTile(
                              track: track,
                              liked: store.isLiked(track),
                              onTap: () => player.playTrack(
                                track,
                                queue: tracks,
                                index: i,
                              ),
                              onLike: () => store.toggleLike(track),
                              onMore: () => showTrackMenu(
                                context,
                                ref,
                                track,
                                playlist: name,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
    this.onPlay,
    this.onDelete,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback? onPlay;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              IconCircle(
                icon: Icons.arrow_back_rounded,
                size: 40,
                onTap: onBack,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11.5, color: kMuted),
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconCircle(
                  icon: Icons.delete_outline_rounded,
                  size: 40,
                  onTap: onDelete,
                ),
              if (onDelete != null) const SizedBox(width: 8),
              IconCircle(
                icon: Icons.play_arrow_rounded,
                size: 44,
                active: true,
                onTap: onPlay,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
