import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

class AppStore extends ChangeNotifier {
  AppStore._(this._prefs);

  static const _kLiked = 'klarwave.liked';
  static const _kRecent = 'klarwave.recent';
  static const _kPlaylists = 'klarwave.playlists';

  static AppStore? _instance;

  static AppStore get instance {
    final store = _instance;
    if (store == null) {
      throw StateError('AppStore.load() harus dipanggil sebelum runApp()');
    }
    return store;
  }

  final SharedPreferences _prefs;
  final List<Track> _liked = [];
  final List<Track> _recent = [];
  final Map<String, List<Track>> _playlists = {};

  static Future<AppStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = AppStore._(prefs).._read();
    _instance = store;
    return store;
  }

  List<Track> get liked => List.unmodifiable(_liked);
  List<Track> get recent => List.unmodifiable(_recent);
  List<String> get playlistNames => _playlists.keys.toList(growable: false);

  List<Track> playlist(String name) =>
      List.unmodifiable(_playlists[name] ?? const <Track>[]);

  bool isLiked(Track track) => _liked.any((x) => x.key == track.key);

  void toggleLike(Track track) {
    final index = _liked.indexWhere((x) => x.key == track.key);
    if (index >= 0) {
      _liked.removeAt(index);
    } else {
      _liked.insert(0, track);
    }
    _persist();
    notifyListeners();
  }

  Future<void> addRecent(Track track) async {
    _recent.removeWhere((x) => x.key == track.key);
    _recent.insert(0, track);
    if (_recent.length > 30) _recent.removeRange(30, _recent.length);
    await _persist();
    notifyListeners();
  }

  void clearRecent() {
    _recent.clear();
    _persist();
    notifyListeners();
  }

  void createPlaylist(String name) {
    final key = name.trim();
    if (key.isEmpty || _playlists.containsKey(key)) return;
    _playlists[key] = [];
    _persist();
    notifyListeners();
  }

  void addToPlaylist(String name, Track track) {
    final list = _playlists[name];
    if (list == null || list.any((x) => x.key == track.key)) return;
    list.add(track);
    _persist();
    notifyListeners();
  }

  void removeFromPlaylist(String name, Track track) {
    _playlists[name]?.removeWhere((x) => x.key == track.key);
    _persist();
    notifyListeners();
  }

  void deletePlaylist(String name) {
    _playlists.remove(name);
    _persist();
    notifyListeners();
  }

  void _read() {
    _liked.addAll(_decode(_prefs.getString(_kLiked)));
    _recent.addAll(_decode(_prefs.getString(_kRecent)));
    final raw = _prefs.getString(_kPlaylists);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) {
        map.forEach((name, value) {
          if (value is List) _playlists[name] = _decodeList(value);
        });
      }
    } catch (_) {}
  }

  List<Track> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      return _decodeList(jsonDecode(raw));
    } catch (_) {
      return const [];
    }
  }

  List<Track> _decodeList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(Track.fromJson)
        .toList();
  }

  Future<void> _persist() async {
    await _prefs.setString(
      _kLiked,
      jsonEncode(_liked.map((e) => e.toJson()).toList()),
    );
    await _prefs.setString(
      _kRecent,
      jsonEncode(_recent.map((e) => e.toJson()).toList()),
    );
    await _prefs.setString(
      _kPlaylists,
      jsonEncode(
        _playlists.map(
          (name, tracks) =>
              MapEntry(name, tracks.map((e) => e.toJson()).toList()),
        ),
      ),
    );
  }
}
