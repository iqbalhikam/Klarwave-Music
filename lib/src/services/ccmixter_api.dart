import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models.dart';

/// Remix dan musik Creative Commons dari ccMixter.
class CcMixterApi {
  CcMixterApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Track>> search(String query, {int limit = 12}) async {
    final cleaned = query.trim();
    if (cleaned.isEmpty) return const [];

    final uri = Uri.https('ccmixter.org', '/api/query', {
      'f': 'json',
      'dataview': 'files',
      'search': cleaned,
      'tags': 'music !sample',
      'limit': '${limit.clamp(1, 30)}',
      'offset': '0',
    });
    final res = await _client.get(uri).timeout(const Duration(seconds: 18));
    if (res.statusCode != 200) throw CcMixterException(res.statusCode);

    final body = jsonDecode(res.body);
    if (body is! List) return const [];

    final tracks = <Track>[];
    for (final entry in body) {
      if (entry is! Map) continue;
      final track = _map(entry);
      if (track != null) tracks.add(track);
    }
    return tracks;
  }

  Track? _map(Map raw) {
    final url = (raw['download_url'] ?? raw['file_url'])?.toString();
    if (url == null || !url.startsWith('http')) return null;

    final id = (raw['id'] ?? raw['upload_id'])?.toString() ?? url;
    return Track(
      id: id,
      title: (raw['upload_name'] ?? raw['title'] ?? 'Tanpa judul').toString(),
      artist: (raw['user_name'] ?? raw['artist_name'] ?? 'ccMixter').toString(),
      source: 'ccmixter',
      duration: _duration(raw['duration']),
      streamUrl: url.replaceFirst('http://', 'https://'),
      sourceUrl: raw['file_page_url']?.toString(),
      license: raw['license_name']?.toString(),
    );
  }

  Duration? _duration(dynamic raw) {
    if (raw is num && raw > 0) return Duration(seconds: raw.round());
    final seconds = int.tryParse(raw?.toString() ?? '');
    if (seconds == null || seconds <= 0) return null;
    return Duration(seconds: seconds);
  }
}

class CcMixterException implements Exception {
  CcMixterException(this.code);

  final int code;

  @override
  String toString() => 'ccMixter error ($code)';
}
