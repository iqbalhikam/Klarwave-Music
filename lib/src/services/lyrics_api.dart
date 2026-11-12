import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models.dart';

/// LRCLIB: database lirik terbuka, tanpa API key.
class LyricsApi {
  LyricsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, Lyrics?> _cache = {};

  static const _headers = {
    'User-Agent': 'Klarwave/1.0 (https://github.com)',
    'Accept': 'application/json',
  };

  Future<Lyrics?> find(Track track) async {
    final key = '${track.title}|${track.artist}'.toLowerCase();
    if (_cache.containsKey(key)) return _cache[key];

    Lyrics? result;
    try {
      final uri = Uri.https('lrclib.net', '/api/get', {
        'artist_name': track.artist,
        'track_name': track.title,
        if (track.duration != null) 'duration': '${track.duration!.inSeconds}',
      });
      final res = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json is Map<String, dynamic>) {
          result = Lyrics(
            synced: json['syncedLyrics'] as String?,
            plain: json['plainLyrics'] as String?,
          );
        }
      }
    } catch (_) {}

    if (result == null || !result.hasContent) {
      try {
        final uri = Uri.https('lrclib.net', '/api/search', {
          'track_name': track.title,
          'artist_name': track.artist,
        });
        final res = await _client
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 12));
        if (res.statusCode == 200) {
          final list = jsonDecode(res.body);
          if (list is List) {
            for (final item in list) {
              if (item is! Map<String, dynamic>) continue;
              final candidate = Lyrics(
                synced: item['syncedLyrics'] as String?,
                plain: item['plainLyrics'] as String?,
              );
              if (candidate.hasContent) {
                result = candidate;
                break;
              }
            }
          }
        }
      } catch (_) {}
    }

    _cache[key] = result;
    return result;
  }
}

class Lyrics {
  const Lyrics({this.synced, this.plain});

  final String? synced;
  final String? plain;

  bool get hasContent =>
      (synced != null && synced!.trim().isNotEmpty) ||
      (plain != null && plain!.trim().isNotEmpty);

  bool get isSynced => synced != null && synced!.trim().isNotEmpty;

  List<LyricLine> get lines => isSynced ? parseLrc(synced!) : const [];

  List<String> get plainLines {
    final source = synced ?? plain;
    if (source == null) return const [];
    return [
      for (final line in source.split('\n'))
        if (line.trim().isNotEmpty) line.trim(),
    ];
  }
}

final _lrcTimestamp =
    RegExp(r'\[(\d{1,2}):(\d{1,2})(?:[.:](\d{1,3}))?\]');

List<LyricLine> parseLrc(String source) {
  final result = <LyricLine>[];
  for (final raw in source.split('\n')) {
    final stamps = _lrcTimestamp.allMatches(raw).toList();
    if (stamps.isEmpty) continue;
    final text = raw.replaceAll(_lrcTimestamp, '').trim();
    if (text.isEmpty) continue;
    for (final stamp in stamps) {
      final minutes = int.parse(stamp.group(1)!);
      final seconds = int.parse(stamp.group(2)!);
      final fraction = stamp.group(3);
      var millis = 0;
      if (fraction != null) {
        millis = int.parse(fraction.padRight(3, '0').substring(0, 3));
      }
      result.add(
        LyricLine(
          Duration(minutes: minutes, seconds: seconds, milliseconds: millis),
          text,
        ),
      );
    }
  }
  result.sort((a, b) => a.time.compareTo(b.time));
  return result;
}
