import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/track.dart';

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  return AudioPlayerService();
});

class AudioPlayerService {
  late final AudioPlayer _player;
  late final AndroidEqualizer _equalizer;

  AudioPlayerService() {
    _equalizer = AndroidEqualizer();
    final pipeline = AudioPipeline(
      androidAudioEffects: [
        _equalizer,
      ],
    );
    _player = AudioPlayer(audioPipeline: pipeline);
    _loadEqualizerPreferences();
  }

  AudioPlayer get player => _player;
  AndroidEqualizer get equalizer => _equalizer;

  Future<void> _loadEqualizerPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Esperamos a que los parámetros estén disponibles antes de aplicar
      final params = await _equalizer.parameters;
      final isEnabled = prefs.getBool('eq_enabled') ?? false;
      _equalizer.setEnabled(isEnabled);

      for (int i = 0; i < params.bands.length; i++) {
        final band = params.bands[i];
        final savedGain = prefs.getDouble('eq_band_$i');
        if (savedGain != null) {
          band.setGain(savedGain);
        }
      }
    } catch (e) {
      print('Error al cargar preferencias del ecualizador: $e');
    }
  }

  Future<void> saveEqualizerGain(int bandIndex, double gain) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('eq_band_$bandIndex', gain);
  }

  Future<void> saveEqualizerEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('eq_enabled', isEnabled);
    await _equalizer.setEnabled(isEnabled);
  }

  Future<void> playStream(Track track, String url) async {
    final mediaItem = MediaItem(
      id: track.youtubeId,
      album: 'SaryMusic Stream',
      title: track.title,
      artist: track.artist,
      artUri:
          track.thumbnailUrl.isNotEmpty ? Uri.parse(track.thumbnailUrl) : null,
    );

    // Reproducción INSTANTÁNEA mediante HTTP stream
    final audioSource = AudioSource.uri(
      Uri.parse(url),
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
