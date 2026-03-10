import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider que expone el progreso de cada descarga activa.
/// El mapa es: { youtubeId: progreso (0.0 a 1.0) }
/// Si no existe la clave, la canción no está descargando.
final downloadProvider =
    StateNotifierProvider<DownloadNotifier, Map<String, double>>((ref) {
  return DownloadNotifier();
});

class DownloadNotifier extends StateNotifier<Map<String, double>> {
  DownloadNotifier() : super({});

  void setProgress(String youtubeId, double progress) {
    state = {...state, youtubeId: progress};
  }

  void finish(String youtubeId) {
    final next = Map<String, double>.from(state);
    next.remove(youtubeId);
    state = next;
  }

  bool isDownloading(String youtubeId) => state.containsKey(youtubeId);

  double getProgress(String youtubeId) => state[youtubeId] ?? 0.0;
}
