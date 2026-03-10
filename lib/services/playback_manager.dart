import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../data/models/track.dart';
import 'audio_player_service.dart';
import 'youtube_service.dart';
import 'play_history_service.dart';

final playbackManagerProvider = Provider<PlaybackManager>((ref) {
  final audioService = ref.read(audioPlayerServiceProvider);
  final ytService = ref.read(youtubeServiceProvider);
  return PlaybackManager(audioService, ytService);
});

class PlaybackManager {
  final AudioPlayerService _audioService;
  final YoutubeService _ytService;
  final _historyService = PlayHistoryService();

  List<Track> _queue = [];
  int _currentIndex = 0;
  StreamSubscription? _completionSub;

  // Stream que emite el track actual INMEDIATAMENTE al cambiar (sin esperar al audio)
  final _currentTrackController = StreamController<Track?>.broadcast();
  Stream<Track?> get currentTrackStream => _currentTrackController.stream;
  Track? get currentTrack => _queue.isNotEmpty && _currentIndex < _queue.length
      ? _queue[_currentIndex]
      : null;

  // Stream para indicar que se está extrayendo el link o haciendo buffering de red
  final _isBufferingController = StreamController<bool>.broadcast();
  Stream<bool> get isBufferingStream => _isBufferingController.stream;

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

    // ✅ Registrar la reproducción para análisis de gustos
    _historyService.record(track);

    if (track.localFilePath != null) {
      _isBufferingController.add(false); // local es instantáneo
      await _audioService.playLocal(track, track.localFilePath!);
      return;
    }

    try {
      _isBufferingController.add(true); // ⏳ Cargando URL de YouTube

      // Reproducción instantánea mediante URL directa (Streaming HTTP)
      final audioUrl = await _ytService.getAudioUrl(track.youtubeId);
      if (audioUrl != null) {
        print('[PlaybackManager] URL obtenida, iniciando streaming...');
        await _audioService.playStream(track, audioUrl);
      } else {
        print('[PlaybackManager] Error: No se pudo obtener la URL del audio');
        _playNext();
      }
    } catch (e) {
      print('[PlaybackManager] Error reproduciendo canción: $e');
      _playNext();
    } finally {
      _isBufferingController.add(false); // ✅ Terminó de cargar (éxito o error)
    }
  }

  void dispose() {
    _completionSub?.cancel();
    _currentTrackController.close();
    _isBufferingController.close();
  }
}
