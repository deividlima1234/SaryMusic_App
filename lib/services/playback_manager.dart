import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../data/models/track.dart';
import 'audio_player_service.dart';
import 'youtube_service.dart';

final playbackManagerProvider = Provider<PlaybackManager>((ref) {
  final audioService = ref.read(audioPlayerServiceProvider);
  final ytService = ref.read(youtubeServiceProvider);
  return PlaybackManager(audioService, ytService);
});

class PlaybackManager {
  final AudioPlayerService _audioService;
  final YoutubeService _ytService;

  List<Track> _queue = [];
  int _currentIndex = 0;
  StreamSubscription? _completionSub;

  // Stream que emite el track actual INMEDIATAMENTE al cambiar (sin esperar al audio)
  final _currentTrackController = StreamController<Track?>.broadcast();
  Stream<Track?> get currentTrackStream => _currentTrackController.stream;
  Track? get currentTrack => _queue.isNotEmpty && _currentIndex < _queue.length
      ? _queue[_currentIndex]
      : null;

  PlaybackManager(this._audioService, this._ytService) {
    _completionSub = _audioService.player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _playNext();
      }
    });
  }

  int get currentIndex => _currentIndex;
  List<Track> get queue => List.unmodifiable(_queue);
  bool get hasNext => _currentIndex < _queue.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  Future<void> setQueueAndPlay(List<Track> tracks, int index) async {
    _queue = List.from(tracks);
    _currentIndex = index.clamp(0, tracks.length - 1);
    _emitCurrentTrack();
    await _playCurrentTrack();
  }

  Future<void> skipToNext() async {
    if (!hasNext) return;
    _currentIndex++;
    _emitCurrentTrack(); // Actualiza metadata INMEDIATAMENTE
    await _playCurrentTrack();
  }

  Future<void> skipToPrevious() async {
    final pos = _audioService.player.position;
    if (pos.inSeconds > 3) {
      await _audioService.seek(Duration.zero);
      return;
    }
    if (!hasPrevious) return;
    _currentIndex--;
    _emitCurrentTrack(); // Actualiza metadata INMEDIATAMENTE
    await _playCurrentTrack();
  }

  Future<void> _playNext() async {
    if (!hasNext) return;
    _currentIndex++;
    _emitCurrentTrack();
    await _playCurrentTrack();
  }

  void _emitCurrentTrack() {
    _currentTrackController.add(currentTrack);
  }

  Future<void> _playCurrentTrack() async {
    if (_queue.isEmpty) return;
    final track = _queue[_currentIndex];

    if (track.localFilePath != null) {
      await _audioService.playLocal(track, track.localFilePath!);
      return;
    }

    final streamInfo = await _ytService.getStreamInfo(track.youtubeId);
    if (streamInfo == null) {
      if (hasNext) {
        _currentIndex++;
        _emitCurrentTrack();
        await _playCurrentTrack();
      }
      return;
    }

    _ytService.downloadAudioProgressive(
      streamInfo,
      track.youtubeId,
      onBufferReady: (filePath) async {
        // Solo reproducir si este track sigue siendo el actual
        if (currentTrack?.youtubeId == track.youtubeId) {
          await _audioService.playStream(track, filePath);
        }
      },
    );
  }

  void dispose() {
    _completionSub?.cancel();
    _currentTrackController.close();
  }
}
