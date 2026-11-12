class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.source,
    this.artwork,
    this.artworkUrl,
    this.audioUrl,
    this.duration,
    this.genre,
    this.streamUrl,
    this.album,
    this.sourceUrl,
    this.license,
    this.year,
  });

  final String id;
  final String title;
  final String artist;
  final String source;
  final String? artwork;
  final String? artworkUrl; // Alias untuk artwork
  final String? audioUrl; // Alias untuk streamUrl
  final Duration? duration;
  final String? genre;
  final String? streamUrl;
  final String? album;
  final String? sourceUrl;
  final String? license;
  final int? year;

  String get key => '$source:$id';
  bool get isLive => source == 'radio';

  String get sourceLabel => switch (source) {
        'audius' => 'Audius',
        'archive' => 'Internet Archive',
        'openverse' => 'Openverse',
        'ccmixter' => 'ccMixter',
        'radio' => 'Radio Browser',
        'youtube' => 'YouTube Music',
        'itunes' => 'iTunes',
        'local' => 'Musik lokal',
        _ => source,
      };

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? source,
    String? artwork,
    String? artworkUrl,
    String? audioUrl,
    Duration? duration,
    String? genre,
    String? streamUrl,
    String? album,
    String? sourceUrl,
    String? license,
    int? year,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      source: source ?? this.source,
      artwork: artwork ?? this.artwork,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      genre: genre ?? this.genre,
      streamUrl: streamUrl ?? this.streamUrl,
      album: album ?? this.album,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      license: license ?? this.license,
      year: year ?? this.year,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'source': source,
        if (artwork != null) 'artwork': artwork,
        if (artworkUrl != null) 'artworkUrl': artworkUrl,
        if (audioUrl != null) 'audioUrl': audioUrl,
        if (duration != null) 'duration': duration!.inSeconds,
        if (genre != null) 'genre': genre,
        if (streamUrl != null) 'streamUrl': streamUrl,
        if (album != null) 'album': album,
        if (sourceUrl != null) 'sourceUrl': sourceUrl,
        if (license != null) 'license': license,
        if (year != null) 'year': year,
      };

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        id: json['id'].toString(),
        title: (json['title'] ?? 'Tanpa judul').toString(),
        artist: (json['artist'] ?? 'Artis tidak dikenal').toString(),
        source: (json['source'] ?? 'audius').toString(),
        artwork: json['artwork']?.toString(),
        artworkUrl: json['artworkUrl']?.toString(),
        audioUrl: json['audioUrl']?.toString(),
        duration: json['duration'] is num
            ? Duration(seconds: (json['duration'] as num).round())
            : null,
        genre: json['genre']?.toString(),
        streamUrl: json['streamUrl']?.toString(),
        album: json['album']?.toString(),
        sourceUrl: json['sourceUrl']?.toString(),
        license: json['license']?.toString(),
        year: json['year'] is num ? (json['year'] as num).toInt() : null,
      );
}

class LyricLine {
  const LyricLine(this.time, this.text);

  final Duration time;
  final String text;
}
