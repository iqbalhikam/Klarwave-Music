import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models.dart';
import '../services/audius_api.dart';
import '../services/store.dart';

class PlayerController extends ChangeNotifier {
  PlayerController({required this.store, required this.audius}) {
    _player.playbackEventStream.listen(
      (_) {},
      onError: (Object error, StackTrace stack) {
        loading = false;
        this.error = 'Streaming gagal. Coba lagi atau pilih lagu lain.';
        notifyListeners();
      },
    );
    _player.playerStateStream.listen((state) {
      final isPlaying = state.playing &&
          state.processingState != ProcessingState.completed;
      if (isPlaying != playing) {
        playing = isPlaying;
        notifyListeners();
      }
      if (state.processingState == ProcessingState.completed) {
        _handleCompleted();
      }
    });
    _player.positionStream.listen((value) {
      position = value;
      notifyListeners();
    });
    _player.durationStream.listen((value) {
      duration = value ?? current?.duration;
      notifyListeners();
    });
  }

  final AppStore store;
  final AudiusApi audius;
  final AudioPlayer _player = AudioPlayer();

  final List<Track> _queue = [];
  int _index = 0;

  bool loading = false;
  bool playing = false;
  bool shuffle = false;
  bool repeatOne = false;
  bool repeatAll = true;
  String? error;
  Duration position = Duration.zero;
  Duration? duration;
  Duration? sleepRemaining;
  Timer? _sleepTimer;
  bool _advancing = false;
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  List<Track> get queue => List.unmodifiable(_queue);
  int get index => _index;
  Track? get current =>
      _index >= 0 && _index < _queue.length ? _queue[_index] : null;
  bool get hasNext => _queue.isNotEmpty;
  bool get hasPrevious => _index > 0;

  Future<void> playTrack(
    Track track, {
    List<Track>? queue,
    int index = 0,
  }) async {
    final list = (queue == null || queue.isEmpty) ? <Track>[track] : queue;
    _queue
      ..clear()
      ..addAll(list);
    _index = index.clamp(0, _queue.length - 1).toInt();
    if (_queue[_index].key != track.key) {
      _queue[_index] = track;
    }
    await _load();
  }

  Future<void> _load() async {
    final track = current;
    if (track == null) return;
    loading = true;
    error = null;
    position = Duration.zero;
    duration = track.duration;
    notifyListeners();

    try {
      final url = track.streamUrl ?? await audius.streamUrl(track.id);
      final tag = MediaItem(
        id: track.key,
        title: track.title,
        artist: track.artist,
        album: track.album,
        artUri: track.artwork == null ? null : Uri.tryParse(track.artwork!),
        duration: track.duration,
        isLive: track.isLive,
      );
      final source = AudioSource.uri(Uri.parse(url), tag: tag);
      await _player.setAudioSource(source);
      await _player.play();
      await store.addRecent(track);
    } catch (_) {
      error = 'Tidak bisa memutar "${track.title}".';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> retry() => _load();

  Future<void> toggle() async {
    if (current == null || loading) return;
    if (playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration target) async {
    if (current?.isLive ?? false) return;
    await _player.seek(target);
  }

  void jumpTo(int index) {
    if (index < 0 || index >= _queue.length) return;
    _index = index;
    _load();
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;
    if (shuffle && _queue.length > 1) {
      final candidates =
          List<int>.generate(_queue.length, (i) => i)..remove(_index);
      _index = candidates[Random().nextInt(candidates.length)];
    } else if (_index < _queue.length - 1) {
      _index++;
    } else if (repeatAll) {
      _index = 0;
    } else {
      await _player.stop();
      playing = false;
      notifyListeners();
      return;
    }
    await _load();
  }

  Future<void> previous() async {
    if (position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    if (_index > 0) {
      _index--;
      await _load();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  void toggleShuffle() {
    shuffle = !shuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    if (repeatAll) {
      repeatAll = false;
      repeatOne = true;
    } else if (repeatOne) {
      repeatOne = false;
      repeatAll = false;
    } else {
      repeatAll = true;
    }
    notifyListeners();
  }

  void startSleepTimer(Duration delay) {
    _sleepTimer?.cancel();
    sleepRemaining = delay;
    notifyListeners();
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = sleepRemaining! - const Duration(seconds: 1);
      if (next <= Duration.zero) {
        timer.cancel();
        sleepRemaining = null;
        _player.pause();
      } else {
        sleepRemaining = next;
      }
      notifyListeners();
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    sleepRemaining = null;
    notifyListeners();
  }

  Future<void> _handleCompleted() async {
    if (_advancing) return;
    _advancing = true;
    try {
      if (repeatOne) {
        await _player.seek(Duration.zero);
        await _player.play();
      } else {
        await next();
      }
    } finally {
      _advancing = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sleepTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}
