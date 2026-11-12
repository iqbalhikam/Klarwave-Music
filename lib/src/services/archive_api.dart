import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models.dart';

/// Audio domain publik dan Creative Commons dari Internet Archive.
class ArchiveApi {
  ArchiveApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Track>> search(String query, {int limit = 12}) async {
    final cleaned = query.trim();
    if (cleaned.isEmpty) return const [];
    final docs = await _docs(
      '($cleaned) AND mediatype:(audio) AND -collection:(podcasts)',
      limit: limit,
    );
    return _tracks(docs);
  }

  Future<List<Track>> indonesian({int limit = 10}) {
    return search(
      '(subject:(indonesia OR keroncong OR gamelan OR dangdut OR "lagu daerah") '
      'OR title:(indonesia))',
      limit: limit,
    );
  }

  Future<List<String>> _docs(String query, {required int limit}) async {
    final uri = Uri.https('archive.org', '/advancedsearch.php', {
      'q': query,
      'rows': '${limit.clamp(1, 30)}',
      'page': '1',
      'output': 'json',
      'fl[]': 'identifier',
    });
    final res = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw ArchiveException(res.statusCode);
    final body = jsonDecode(res.body);
    final response = body is Map ? body['response'] : null;
    final docs = response is Map ? response['docs'] : null;
    if (docs is! List) return const [];
    return docs
        .whereType<Map>()
        .map((doc) => doc['identifier']?.toString())
        .whereType<String>()
        .toList();
  }

  Future<List<Track>> _tracks(List<String> identifiers) async {
    final results = await Future.wait(identifiers.map(_itemTrack));
    return results.whereType<Track>().toList();
  }

  Future<Track?> _itemTrack(String identifier) async {
    try {
      final encodedId = Uri.encodeComponent(identifier);
      final res = await _client
          .get(Uri.https('archive.org', '/metadata/$encodedId'))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      if (body is! Map) return null;
      final files = body['files'];
      if (files is! List) return null;
      final metadata = body['metadata'];
      final meta = metadata is Map ? metadata : const {};

      Map? best;
      var bestRank = 99;
      for (final entry in files) {
        if (entry is! Map) continue;
        final name = entry['name']?.toString() ?? '';
        if (name.isEmpty) continue;
        final rank = _rank(entry['format']?.toString() ?? '');
        if (rank >= bestRank) continue;
        final size = entry['size'];
        if (size is String && size == '0') continue;
        best = entry;
        bestRank = rank;
      }
      if (best == null || bestRank >= 99) return null;

      final name = best['name'].toString();
      final encodedName =
          name.split('/').map(Uri.encodeComponent).join('/');
      final stream = 'https://archive.org/download/$encodedId/$encodedName';
      final title = _text(
        best['title'] ?? meta['title'] ?? identifier,
        fallback: identifier,
      );
      final artist = _text(meta['creator'], fallback: 'Internet Archive');
      final license = meta['licenseurl']?.toString();

      return Track(
        id: '$identifier/$name',
        title: title,
        artist: artist,
        source: 'archive',
        artwork: 'https://archive.org/services/img/$encodedId',
        duration: _parseLength(best['length']),
        genre: _text(meta['genre'], fallback: ''),
        album: _text(meta['album'], fallback: ''),
        streamUrl: stream,
        sourceUrl: 'https://archive.org/details/$encodedId',
        license: license,
      );
    } catch (_) {
      return null;
    }
  }

  int _rank(String format) {
    return switch (format.toLowerCase()) {
      'vbr mp3' => 0,
      'mp3' => 1,
      '128kbps mp3' => 2,
      '64kbps mp3' => 3,
      'ogg vorbis' => 4,
      'flac' => 5,
      _ => 99,
    };
  }

  String _text(dynamic value, {required String fallback}) {
    if (value is List && value.isNotEmpty) return value.first.toString();
    if (value is String && value.trim().isNotEmpty) return value;
    return fallback;
  }

  Duration? _parseLength(dynamic raw) {
    if (raw is num) return Duration(seconds: raw.round());
    final text = raw?.toString() ?? '';
    if (text.contains(':')) {
      final parts = text.split(':').map(int.tryParse).toList();
      if (parts.any((p) => p == null)) return null;
      if (parts.length == 2) {
        return Duration(minutes: parts[0]!, seconds: parts[1]!);
      }
      if (parts.length == 3) {
        return Duration(
          hours: parts[0]!,
          minutes: parts[1]!,
          seconds: parts[2]!,
        );
      }
      return null;
    }
    final seconds = double.tryParse(text);
    if (seconds == null || seconds <= 0) return null;
    return Duration(seconds: seconds.round());
  }
}

class ArchiveException implements Exception {
  ArchiveException(this.code);

  final int code;

  @override
  String toString() => 'Internet Archive error ($code)';
}
