import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models.dart';

/// Openverse mengindeks audio Creative Commons dari Jamendo, Wikimedia,
/// Freesound, dan sumber terbuka lain tanpa API key.
class OpenverseApi {
  OpenverseApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, _CacheEntry> _cache = {};
  DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);

  // Batas anonim Openverse 20 permintaan/menit.
  static const _minGap = Duration(seconds: 3);
  static const _ttl = Duration(minutes: 10);

  Future<List<Track>> search(String query, {int limit = 15}) async {
    final cleaned = query.trim();
    if (cleaned.isEmpty) return const [];

    final cached = _cache[cleaned];
    if (cached != null && DateTime.now().difference(cached.at) < _ttl) {
      return cached.tracks;
    }

    final gap = DateTime.now().difference(_lastRequest);
    if (gap < _minGap) {
      await Future<void>.delayed(_minGap - gap);
    }
    _lastRequest = DateTime.now();

    final uri = Uri.https('api.openverse.org', '/v1/audio/', {
      'q': cleaned,
      'page_size': '${limit.clamp(1, 20)}',
      'category': 'music',
      'license_type': 'all-cc',
    });
    final res = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 18));
    if (res.statusCode != 200) throw OpenverseException(res.statusCode);

    final body = jsonDecode(res.body);
    final results = body is Map ? body['results'] : null;
    if (results is! List) return const [];

    final tracks = <Track>[];
    for (final entry in results) {
      if (entry is! Map) continue;
      final track = _map(entry);
      if (track != null) tracks.add(track);
    }
    _cache[cleaned] = _CacheEntry(DateTime.now(), tracks);
    return tracks;
  }

  Track? _map(Map raw) {
    final url = raw['url']?.toString();
    if (url == null || !url.startsWith('http')) return null;

    final durationMs = raw['duration'];
    final duration = durationMs is num && durationMs > 0
        ? Duration(milliseconds: durationMs.round())
        : null;
    if (duration != null && duration.inSeconds < 20) return null;

    final landing = raw['foreign_landing_url']?.toString();
    final licenseUrl = raw['license_url']?.toString();

    return Track(
      id: raw['id']?.toString() ?? url,
      title: raw['title']?.toString() ?? 'Tanpa judul',
      artist: raw['creator']?.toString() ??
          raw['source']?.toString() ??
          'Openverse',
      source: 'openverse',
      artwork: raw['thumbnail']?.toString(),
      duration: duration,
      streamUrl: url.replaceFirst('http://', 'https://'),
      sourceUrl: landing ?? licenseUrl,
      license: _license(raw),
    );
  }

  String? _license(Map raw) {
    final code = raw['license']?.toString();
    if (code == null || code.isEmpty) return null;
    final base = code.toLowerCase() == 'cc0' ? 'CC0' : 'CC ${code.toUpperCase()}';
    final version = raw['license_version']?.toString();
    if (version == null || version.isEmpty) return base;
    return '$base $version';
  }
}

class _CacheEntry {
  const _CacheEntry(this.at, this.tracks);

  final DateTime at;
  final List<Track> tracks;
}

class OpenverseException implements Exception {
  OpenverseException(this.code);

  final int code;

  @override
  String toString() => 'Openverse error ($code)';
}
