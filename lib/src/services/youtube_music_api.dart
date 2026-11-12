import 'dart:async';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models.dart';

/// YouTube Music API service - no backend required
/// Menggunakan youtube_explode_dart untuk akses langsung
class YouTubeMusicApi {
  YouTubeMusicApi() : _yt = YoutubeExplode();

  final YoutubeExplode _yt;

  /// Search tracks dari YouTube Music
  Future<List<Track>> search(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return const [];

    try {
      // Search dengan filter musik
      final searchQuery = '$query music audio';
      final results = await _yt.search.search(searchQuery);

      final tracks = <Track>[];
      for (final video in results.take(limit)) {
        // Skip videos yang terlalu pendek (< 30 detik) atau terlalu panjang (> 15 menit)
        final duration = video.duration;
        if (duration == null) continue;
        if (duration.inSeconds < 30 || duration.inSeconds > 900) continue;

        // Ekstrak artist dan title dari video title
        final parsed = _parseTitle(video.title);

        tracks.add(Track(
          id: 'yt_${video.id.value}',
          title: parsed.title,
          artist: parsed.artist,
          album: null,
          duration: duration,
          artworkUrl: video.thumbnails.highResUrl,
          audioUrl:
              'yt://${video.id.value}', // Placeholder, akan di-resolve saat play
          source: 'youtube',
          license: null,
          year: video.uploadDate?.year,
        ));
      }

      return tracks;
    } catch (e) {
      throw YouTubeMusicException('Gagal mencari musik: $e');
    }
  }

  /// Get direct audio stream URL untuk playback
  Future<String> getAudioUrl(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);

      // Pilih audio stream dengan kualitas terbaik
      final audioOnly = manifest.audioOnly;
      if (audioOnly.isEmpty) {
        throw YouTubeMusicException('Tidak ada audio stream tersedia');
      }

      // Prioritas: opus > m4a > mp4
      var best = audioOnly.first;
      for (final stream in audioOnly) {
        if (stream.codec.mimeType.contains('opus')) {
          best = stream;
          break;
        } else if (stream.codec.mimeType.contains('m4a') &&
            !best.codec.mimeType.contains('opus')) {
          best = stream;
        }
      }

      return best.url.toString();
    } catch (e) {
      throw YouTubeMusicException('Gagal mendapatkan audio URL: $e');
    }
  }

  /// Get trending/popular music
  Future<List<Track>> getTrending({int limit = 20}) async {
    try {
      // Gunakan query populer untuk mendapatkan trending music
      final trendingQueries = [
        'top hits 2024',
        'popular music',
        'trending songs',
      ];

      final allTracks = <Track>[];
      for (final query in trendingQueries) {
        final tracks = await search(query, limit: limit ~/ trendingQueries.length);
        allTracks.addAll(tracks);
        if (allTracks.length >= limit) break;
      }

      return allTracks.take(limit).toList();
    } catch (e) {
      throw YouTubeMusicException('Gagal mendapatkan trending musik: $e');
    }
  }

  /// Parse video title untuk ekstrak artist dan title
  _ParsedTitle _parseTitle(String videoTitle) {
    // Pattern umum: "Artist - Title" atau "Artist: Title" atau "Title by Artist"
    final patterns = [
      RegExp(r'^(.+?)\s*[-–—]\s*(.+)$'), // Artist - Title
      RegExp(r'^(.+?)\s*:\s*(.+)$'), // Artist: Title
      RegExp(r'^(.+?)\s+by\s+(.+)$', caseSensitive: false), // Title by Artist
      RegExp(
          r'^(.+?)\s*\|\s*(.+)$'), // Artist | Title (kadang digunakan di YouTube)
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(videoTitle);
      if (match != null) {
        var part1 = match.group(1)!.trim();
        var part2 = match.group(2)!.trim();

        // Clean up common suffixes
        part1 = _cleanTitle(part1);
        part2 = _cleanTitle(part2);

        // Untuk "by Artist", part1 adalah title, part2 adalah artist
        if (videoTitle.toLowerCase().contains(' by ')) {
          return _ParsedTitle(title: part1, artist: part2);
        }

        // Untuk format lain, part1 adalah artist, part2 adalah title
        return _ParsedTitle(title: part2, artist: part1);
      }
    }

    // Fallback: gunakan full title dan artist "Unknown"
    return _ParsedTitle(
      title: _cleanTitle(videoTitle),
      artist: 'Unknown Artist',
    );
  }

  String _cleanTitle(String title) {
    // Remove common video suffixes
    final patterns = [
      RegExp(r'\s*\(official\s+(video|audio|music\s+video)\)', caseSensitive: false),
      RegExp(r'\s*\[official\s+(video|audio|music\s+video)\]', caseSensitive: false),
      RegExp(r'\s*-\s*(official\s+)?(video|audio|music\s+video)', caseSensitive: false),
      RegExp(r'\s*\(.*?lyrics?\)', caseSensitive: false),
      RegExp(r'\s*\[.*?lyrics?\]', caseSensitive: false),
      RegExp(r'\s*\(HD\)', caseSensitive: false),
      RegExp(r'\s*\[HD\]', caseSensitive: false),
      RegExp(r'\s*\d{4}', caseSensitive: false), // Remove year at the end
    ];

    var cleaned = title;
    for (final pattern in patterns) {
      cleaned = cleaned.replaceAll(pattern, '');
    }

    return cleaned.trim();
  }

  void dispose() {
    _yt.close();
  }
}

class _ParsedTitle {
  const _ParsedTitle({required this.title, required this.artist});

  final String title;
  final String artist;
}

class YouTubeMusicException implements Exception {
  const YouTubeMusicException(this.message);

  final String message;

  @override
  String toString() => message;
}
