import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models.dart';

/// iTunes Search API service - untuk high-quality artwork dan metadata
/// API publik dari Apple, tidak perlu API key
class ITunesApi {
  ITunesApi({http.Client? client})
      : _client = client ?? http.Client(),
        _baseUrl = 'https://itunes.apple.com';

  final http.Client _client;
  final String _baseUrl;

  /// Search tracks dengan metadata berkualitas dari iTunes
  Future<List<Track>> search(String query, {int limit = 25}) async {
    if (query.trim().isEmpty) return const [];

    try {
      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
        'term': query,
        'media': 'music',
        'entity': 'song',
        'limit': limit.toString(),
        'country': 'US', // Default to US store for better results
      });

      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw ITunesException(
            'iTunes API error: ${response.statusCode} ${response.reasonPhrase}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];

      return results.map((item) => _parseTrack(item)).toList();
    } catch (e) {
      throw ITunesException('Gagal mencari di iTunes: $e');
    }
  }

  /// Get high-quality artwork URL untuk track
  /// Mengembalikan artwork URL dengan resolusi yang diminta
  String getArtworkUrl(String? originalUrl, {int size = 600}) {
    if (originalUrl == null || originalUrl.isEmpty) return '';

    // iTunes artwork URL format: https://...../100x100bb.jpg
    // Replace dengan size yang diinginkan
    return originalUrl
        .replaceAll(RegExp(r'\d+x\d+bb\.jpg$'), '${size}x${size}bb.jpg');
  }

  /// Search dan enhance metadata
  /// Digunakan untuk memperkaya metadata dari sumber lain
  Future<Track?> enhanceMetadata(String title, String artist) async {
    try {
      final query = '$artist $title';
      final results = await search(query, limit: 5);

      if (results.isEmpty) return null;

      // Cari hasil yang paling cocok
      final normalizedTitle = _normalize(title);
      final normalizedArtist = _normalize(artist);

      for (final track in results) {
        final trackTitle = _normalize(track.title);
        final trackArtist = _normalize(track.artist);

        // Simple fuzzy matching
        if (trackTitle.contains(normalizedTitle) ||
            normalizedTitle.contains(trackTitle)) {
          if (trackArtist.contains(normalizedArtist) ||
              normalizedArtist.contains(trackArtist)) {
            return track;
          }
        }
      }

      // Fallback: return first result
      return results.first;
    } catch (e) {
      return null; // Silent fail untuk enhancement
    }
  }

  Track _parseTrack(Map<String, dynamic> item) {
    final trackId = item['trackId'] as int?;
    final trackName = item['trackName'] as String? ?? 'Unknown';
    final artistName = item['artistName'] as String? ?? 'Unknown Artist';
    final albumName = item['collectionName'] as String?;
    final artworkUrl = item['artworkUrl100'] as String?;
    final previewUrl = item['previewUrl'] as String?; // 30-second preview
    final trackTimeMillis = item['trackTimeMillis'] as int? ?? 0;
    final releaseDate = item['releaseDate'] as String?;

    // Parse release year
    int? year;
    if (releaseDate != null) {
      try {
        year = DateTime.parse(releaseDate).year;
      } catch (_) {}
    }

    return Track(
      id: 'itunes_$trackId',
      title: trackName,
      artist: artistName,
      album: albumName,
      duration: Duration(milliseconds: trackTimeMillis),
      artworkUrl: getArtworkUrl(artworkUrl, size: 600), // High-res artwork
      audioUrl: previewUrl ?? '', // Preview only
      source: 'itunes',
      license: 'Preview only - 30 seconds',
      year: year,
    );
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  void dispose() {
    _client.close();
  }
}

class ITunesException implements Exception {
  const ITunesException(this.message);

  final String message;

  @override
  String toString() => message;
}
