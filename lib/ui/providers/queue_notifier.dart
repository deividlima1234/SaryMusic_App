import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/track.dart';

class QueueState {
  final List<Track> queue;
  final int currentIndex;

  const QueueState({this.queue = const [], this.currentIndex = 0});

  Track? get currentTrack => queue.isNotEmpty && currentIndex < queue.length
      ? queue[currentIndex]
      : null;

  bool get hasNext => currentIndex < queue.length - 1;
  bool get hasPrevious => currentIndex > 0;

  QueueState copyWith({List<Track>? queue, int? currentIndex}) {
    return QueueState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

final queueProvider = StateNotifierProvider<QueueNotifier, QueueState>((ref) {
  return QueueNotifier();
});

class QueueNotifier extends StateNotifier<QueueState> {
  QueueNotifier() : super(const QueueState());

  void setQueue(List<Track> tracks, int index) {
    state = QueueState(
        queue: tracks, currentIndex: index.clamp(0, tracks.length - 1));
  }

  /// Avanza a la siguiente canción. Retorna true si hay siguiente.
  bool next() {
    if (!state.hasNext) return false;
    state = state.copyWith(currentIndex: state.currentIndex + 1);
    return true;
  }

  /// Retrocede a la canción anterior. Retorna true si hay anterior.
  bool previous() {
    if (!state.hasPrevious) return false;
    state = state.copyWith(currentIndex: state.currentIndex - 1);
    return true;
  }
}
