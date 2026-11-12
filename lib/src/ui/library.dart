import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'collection.dart';
import 'kit.dart';
import 'sheets.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider);
    final liked = store.liked;
    final recent = store.recent;
    final names = store.playlistNames;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 200),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Koleksi',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Semua milikmu, tersimpan lokal.',
                    style: TextStyle(fontSize: 11.5, color: kMuted),
                  ),
                ],
              ),
            ),
            IconCircle(
              icon: Icons.add_rounded,
              size: 42,
              active: true,
              onTap: () async {
                final name = await showCreatePlaylistDialog(context);
                if (name != null && name.isNotEmpty) {
                  store.createPlaylist(name);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        GlassPanel(
          radius: 26,
          padding: const EdgeInsets.all(16),
          opacity: 0.13,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TrackListPage(title: 'Disukai', tracks: liked),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF7EA8), Color(0xFFFF4D6D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF4D6D).withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFF24060E),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Disukai',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${liked.length} lagu',
                      style: const TextStyle(fontSize: 12, color: kMuted),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white38,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SectionTitle(
          'Playlist',
          trailing: TextButton(
            onPressed: () async {
              final name = await showCreatePlaylistDialog(context);
              if (name != null && name.isNotEmpty) {
                store.createPlaylist(name);
              }
            },
            child: const Text(
              'Buat baru',
              style: TextStyle(fontSize: 12, color: kAccentB),
            ),
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final name in names)
                  SizedBox(
                    width: width,
                    child: GlassPanel(
                      radius: 22,
                      padding: const EdgeInsets.all(14),
                      opacity: 0.09,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PlaylistPage(name: name),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(13),
                              gradient: kGradient,
                            ),
                            child: const Icon(
                              Icons.queue_music_rounded,
                              size: 20,
                              color: Color(0xFF0A0A12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${store.playlist(name).length} lagu',
                            style: const TextStyle(
                              fontSize: 11,
                              color: kMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(
                  width: width,
                  child: GlassPanel(
                    radius: 22,
                    padding: const EdgeInsets.all(14),
                    opacity: 0.05,
                    onTap: () async {
                      final name = await showCreatePlaylistDialog(context);
                      if (name != null && name.isNotEmpty) {
                        store.createPlaylist(name);
                      }
                    },
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          size: 40,
                          color: Colors.white38,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Playlist baru',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Susun lagu favoritmu',
                          style: TextStyle(fontSize: 11, color: kMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 26),
        SectionTitle(
          'Riwayat',
          trailing: recent.isEmpty
              ? null
              : TextButton(
                  onPressed: store.clearRecent,
                  child: const Text(
                    'Bersihkan',
                    style: TextStyle(fontSize: 12, color: kMuted),
                  ),
                ),
        ),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          const EmptyState(
            icon: Icons.history_rounded,
            title: 'Belum ada riwayat',
            message: 'Lagu yang kamu putar akan muncul di sini.',
          )
        else
          for (var i = 0; i < recent.length && i < 6; i++)
            TrackTile(
              track: recent[i],
              liked: store.isLiked(recent[i]),
              onTap: () => ref.read(playerProvider).playTrack(
                    recent[i],
                    queue: recent,
                    index: i,
                  ),
              onLike: () => store.toggleLike(recent[i]),
              onMore: () => showTrackMenu(context, ref, recent[i]),
            ),
      ],
    );
  }
}
