import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../data/models/track.dart';

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  return AudioPlayerService();
});

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  Future<void> playStream(Track track, String filePath) async {
    final mediaItem = MediaItem(
      id: track.youtubeId,
      album: 'SaryMusic Youtube Cache',
      title: track.title,
      artist: track.artist,
      artUri:
          track.thumbnailUrl.isNotEmpty ? Uri.parse(track.thumbnailUrl) : null,
    );

    // Reproducción nativa 100% confiable y compatible de archivos M4A locales
    final audioSource = AudioSource.uri(
      Uri.file(filePath),
      tag: mediaItem,
    );
    await _player.setAudioSource(audioSource);
    _player.play();
  }

  Future<void> playLocal(Track track, String filePath) async {
    final mediaItem = MediaItem(
      id: track.youtubeId,
      album: 'SaryMusic Local',
      title: track.title,
      artist: track.artist,
      artUri:
          track.thumbnailUrl.isNotEmpty ? Uri.parse(track.thumbnailUrl) : null,
    );
    final audioSource = AudioSource.uri(Uri.file(filePath), tag: mediaItem);
    await _player.setAudioSource(audioSource);
    _player.play();
  }

  void pause() {
    _player.pause();
  }

  void resume() {
    _player.play();
  }

  Future<void> seek(Duration position) {
    return _player.seek(position);
  }
}
