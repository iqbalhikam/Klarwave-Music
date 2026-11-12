import 'dart:async';

import '../models.dart';
import 'archive_api.dart';
import 'audius_api.dart';
import 'ccmixter_api.dart';
import 'openverse_api.dart';
import 'youtube_music_api.dart';
import 'itunes_api.dart';

class MusicAggregator {
  MusicAggregator({
    required this.audius,
    required this.archive,
    required this.openverse,
    required this.ccmixter,
    required this.youtubeMusic,
    required this.itunes,
  });

  final AudiusApi audius;
  final ArchiveApi archive;
  final OpenverseApi openverse;
  final CcMixterApi ccmixter;
  final YouTubeMusicApi youtubeMusic;
  final ITunesApi itunes;

  Future<List<Track>> search(
    String query, {
    String filter = 'semua',
    int limit = 60,
  }) async {
    final cleaned = query.trim();
    if (cleaned.isEmpty) return const [];

    final tasks = <String, Future<List<Track>>>{};
    
    // YouTube Music - prioritas tertinggi
    if (filter == 'semua' || filter == 'youtube') {
      tasks['youtube'] = youtubeMusic.search(cleaned, limit: 20);
    }
    
    if (filter == 'semua' || filter == 'audius') {
      tasks['audius'] = audius.searchTracks(cleaned, limit: 25);
    }
    if (filter == 'semua' || filter == 'archive') {
      tasks['archive'] = archive.search(cleaned, limit: 10);
    }
    if (filter == 'semua' || filter == 'openverse') {
      tasks['openverse'] = openverse.search(cleaned, limit: 15);
    }
    if (filter == 'semua' || filter == 'ccmixter') {
      tasks['ccmixter'] = ccmixter.search(cleaned, limit: 12);
    }
    
    // iTunes untuk metadata enhancement (optional, tidak di-include di semua)
    if (filter == 'itunes') {
      tasks['itunes'] = itunes.search(cleaned, limit: 25);
    }
    
    if (tasks.isEmpty) return const [];

    final results = await Future.wait(tasks.entries.map((entry) async {
      try {
        final tracks =
            await entry.value.timeout(const Duration(seconds: 20));
        return _SourceResult(tracks);
      } catch (_) {
        return const _SourceResult(null);
      }
    }));

    final lists = <List<Track>>[];
    var anyOk = false;
    for (final result in results) {
      final tracks = result.tracks;
      if (tracks != null) {
        anyOk = true;
        if (tracks.isNotEmpty) lists.add(tracks);
      }
    }
    if (!anyOk) throw MusicSourceException();

    final seen = <String>{};
    final out = <Track>[];
    for (final track in _interleave(lists)) {
      final key = '${_norm(track.title)}|${_norm(track.artist)}';
      if (!seen.add(key)) continue;
      out.add(track);
      if (out.length >= limit) break;
    }
    return out;
  }

  /// Get trending/popular music dari berbagai sumber
  Future<List<Track>> getTrending({int limit = 30}) async {
    final tasks = <Future<List<Track>>>[];
    
    // YouTube Music trending
    tasks.add(
      youtubeMusic.getTrending(limit: limit ~/ 2).catchError((_) => <Track>[])
    );
    
    // Audius trending (jika ada)
    tasks.add(
      audius.searchTracks('popular', limit: limit ~/ 2).catchError((_) => <Track>[])
    );
    
    final results = await Future.wait(tasks);
    final allTracks = <Track>[];
    
    for (final tracks in results) {
      allTracks.addAll(tracks);
    }
    
    // Remove duplicates
    final seen = <String>{};
    final unique = <Track>[];
    for (final track in allTracks) {
      final key = '${_norm(track.title)}|${_norm(track.artist)}';
      if (!seen.add(key)) continue;
      unique.add(track);
      if (unique.length >= limit) break;
    }
    
    return unique;
  }
  
  /// Enhance metadata track dengan iTunes API
  /// Berguna untuk mendapatkan artwork berkualitas tinggi
  Future<Track> enhanceTrack(Track track) async {
    try {
      // Skip jika sudah punya artwork bagus
      if (track.artworkUrl != null && track.artworkUrl!.contains('600x600')) {
        return track;
      }
      
      final enhanced = await itunes.enhanceMetadata(track.title, track.artist);
      if (enhanced == null) return track;
      
      // Merge metadata: gunakan audio URL original, tapi artwork dari iTunes
      return track.copyWith(
        artworkUrl: enhanced.artworkUrl,
        album: track.album ?? enhanced.album,
        year: track.year ?? enhanced.year,
      );
    } catch (_) {
      return track; // Silent fail
    }
  }

  List<Track> _interleave(List<List<Track>> lists) {
    final out = <Track>[];
    var index = 0;
    while (true) {
      var added = false;
      for (final list in lists) {
        if (index < list.length) {
          out.add(list[index]);
          added = true;
        }
      }
      if (!added) return out;
      index++;
    }
  }

  String _norm(String value) {
    final lower = value.toLowerCase().trim();
    final normalized = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '');
    return normalized.isEmpty ? lower : normalized;
  }
}

class _SourceResult {
  const _SourceResult(this.tracks);

  final List<Track>? tracks;
}

class MusicSourceException implements Exception {
  @override
  String toString() => 'Semua sumber musik sedang tidak dapat dihubungi';
}
