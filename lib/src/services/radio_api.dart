import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models.dart';

/// Radio Browser: direktori stasiun radio internet gratis dan legal.
class RadioApi {
  RadioApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  int _mirror = 0;

  static const _mirrors = <String>[
    'de1.api.radio-browser.info',
    'de2.api.radio-browser.info',
    'nl1.api.radio-browser.info',
  ];

  Future<List<Track>> stations({
    String? query,
    String? tag,
    String? countryCode,
    int limit = 40,
  }) async {
    final params = <String, String>{
      'limit': '$limit',
      'hidebroken': 'true',
      'order': 'clickcount',
      'reverse': 'true',
      if (query != null && query.isNotEmpty) 'name': query,
      if (tag != null && tag.isNotEmpty) 'tag': tag,
      if (countryCode != null && countryCode.isNotEmpty)
        'countrycode': countryCode,
    };

    for (var attempt = 0; attempt < _mirrors.length; attempt++) {
      final host = _mirrors[(_mirror + attempt) % _mirrors.length];
      try {
        final uri = Uri.https(host, '/json/stations/search', params);
        final res = await _client.get(
          uri,
          headers: const {'User-Agent': 'Klarwave/1.0'},
        ).timeout(const Duration(seconds: 15));
        if (res.statusCode == 200) {
          final list = jsonDecode(res.body);
          if (list is List) {
            _mirror = (_mirror + attempt) % _mirrors.length;
            return list
                .whereType<Map<String, dynamic>>()
                .map(_map)
                .where((t) => t.streamUrl != null)
                .toList();
          }
        }
      } catch (_) {}
    }
    return const [];
  }

  Track _map(Map<String, dynamic> station) {
    final favicon = (station['favicon'] ?? '').toString();
    final bitrate = station['bitrate'];
    final meta = <String>[
      if (station['country'] != null) station['country'].toString(),
      if (station['codec'] != null) station['codec'].toString(),
      if (bitrate is num && bitrate > 0) '${bitrate.round()} kbps',
    ].where((e) => e.isNotEmpty).join(' • ');

    return Track(
      id: (station['stationuuid'] ?? station['url_resolved']).toString(),
      title: (station['name'] ?? 'Radio').toString().trim(),
      artist: meta.isEmpty ? 'Radio internet' : meta,
      source: 'radio',
      artwork: favicon.startsWith('http') ? favicon : null,
      streamUrl: (station['url_resolved'] ?? station['url'])?.toString(),
      genre: station['tags']?.toString(),
    );
  }
}
