class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.source,
    this.artwork,
    this.duration,
    this.genre,
    this.streamUrl,
    this.album,
  });

  final String id;
  final String title;
  final String artist;
  final String source;
  final String? artwork;
  final Duration? duration;
  final String? genre;
  final String? streamUrl;
  final String? album;

  String get key => '$source:$id';
  bool get isLive => source == 'radio';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'source': source,
        if (artwork != null) 'artwork': artwork,
        if (duration != null) 'duration': duration!.inSeconds,
        if (genre != null) 'genre': genre,
        if (streamUrl != null) 'streamUrl': streamUrl,
        if (album != null) 'album': album,
      };

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        id: json['id'].toString(),
        title: (json['title'] ?? 'Tanpa judul').toString(),
        artist: (json['artist'] ?? 'Artis tidak dikenal').toString(),
        source: (json['source'] ?? 'audius').toString(),
        artwork: json['artwork']?.toString(),
        duration: json['duration'] is num
            ? Duration(seconds: (json['duration'] as num).round())
            : null,
        genre: json['genre']?.toString(),
        streamUrl: json['streamUrl']?.toString(),
        album: json['album']?.toString(),
      );
}

class LyricLine {
  const LyricLine(this.time, this.text);

  final Duration time;
  final String text;
}
