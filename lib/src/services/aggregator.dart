import 'dart:async';

import '../models.dart';
import 'archive_api.dart';
import 'audius_api.dart';
import 'ccmixter_api.dart';
import 'openverse_api.dart';

class MusicAggregator {
  MusicAggregator({
    required this.audius,
    required this.archive,
    required this.openverse,
    required this.ccmixter,
  });

  final AudiusApi audius;
  final ArchiveApi archive;
  final OpenverseApi openverse;
  final CcMixterApi ccmixter;

  Future<List<Track>> search(
    String query, {
    String filter = 'semua',
    int limit = 60,
  }) async {
    final cleaned = query.trim();
    if (cleaned.isEmpty) return const [];

    final tasks = <String, Future<List<Track>>>{};
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
