import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models.dart';

/// Audius menyediakan streaming musik gratis dan legal tanpa API key.
class AudiusApi {
  AudiusApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _host;

  static const _fallbackHosts = <String>[
    'https://discoveryprovider.audius.co',
    'https://discoveryprovider2.audius.co',
    'https://discoveryprovider3.audius.co',
  ];

  Future<String> _resolveHost() async {
    final cached = _host;
    if (cached != null) return cached;
    try {
      final res = await _client
          .get(Uri.parse('https://api.audius.co'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body is Map ? body['data'] : null;
        if (data is List && data.isNotEmpty) {
          return _host = data.first.toString();
        }
      }
    } catch (_) {}
    return _host = _fallbackHosts.first;
  }

  Future<dynamic> _get(String path, Map<String, String> query) async {
    final host = await _resolveHost();
    final uri = Uri.parse('$host$path').replace(queryParameters: {
      'app_name': 'Klarwave',
      ...query,
    });
    final res = await _client.get(uri).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw AudiusException(res.statusCode);
    }
    final body = jsonDecode(res.body);
    return body is Map ? body['data'] : null;
  }

  Future<List<Track>> trending({
    String time = 'week',
    String? genre,
    int limit = 24,
  }) async {
    final data = await _get('/v1/tracks/trending', {
      'time': time,
      'limit': '$limit',
      if (genre != null) 'genre': genre,
    });
    return _mapTracks(data);
  }

  Future<List<Track>> searchTracks(String query, {int limit = 30}) async {
    final data = await _get('/v1/tracks/search', {
      'query': query,
      'limit': '$limit',
    });
    return _mapTracks(data);
  }

  Future<String> streamUrl(String id) async {
    final host = await _resolveHost();
    return '$host/v1/tracks/$id/stream?app_name=Klarwave';
  }

  List<Track> _mapTracks(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .where((t) => t['is_streamable'] != false && t['id'] != null)
        .map(_mapTrack)
        .toList();
  }

  Track _mapTrack(Map<String, dynamic> t) {
    final artwork = t['artwork'];
    final user = t['user'];
    final album = t['album_backlink'];
    return Track(
      id: t['id'].toString(),
      title: (t['title'] ?? 'Tanpa judul').toString(),
      artist: user is Map
          ? (user['name'] ?? user['handle'] ?? 'Audius').toString()
          : 'Audius',
      source: 'audius',
      artwork: artwork is Map
          ? (artwork['480x480'] ?? artwork['150x150'])?.toString()
          : null,
      duration: t['duration'] is num
          ? Duration(seconds: (t['duration'] as num).round())
          : null,
      genre: t['genre']?.toString(),
      album: album is Map ? album['playlist_name']?.toString() : null,
    );
  }
}

class AudiusException implements Exception {
  AudiusException(this.code);

  final int code;

  @override
  String toString() => 'Audius error ($code)';
}
