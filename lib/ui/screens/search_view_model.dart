import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/track.dart';
import '../../services/youtube_service.dart';

final searchProvider =
    StateNotifierProvider<SearchNotifier, AsyncValue<List<Track>>>((ref) {
  final youtubeService = ref.read(youtubeServiceProvider);
  return SearchNotifier(youtubeService);
});

class SearchNotifier extends StateNotifier<AsyncValue<List<Track>>> {
  final YoutubeService _youtubeService;

  SearchNotifier(this._youtubeService) : super(const AsyncData([]));

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncData([]);
      return;
    }

    state = const AsyncLoading();
    try {
      final results = await _youtubeService.searchTracks(query);
      state = AsyncData(results);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void clear() {
    state = const AsyncData([]);
  }
}
