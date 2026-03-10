import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/track.dart';

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<Track>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<List<Track>> {
  static const _key = 'user_favorites';

  FavoritesNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];

    final tracks = raw.map((e) {
      final map = jsonDecode(e) as Map<String, dynamic>;
      return Track()
        ..youtubeId = map['id'] ?? ''
        ..title = map['title'] ?? 'Desconocido'
        ..artist = map['artist'] ?? 'Desconocido'
        ..thumbnailUrl = map['thumbnailUrl'] ?? ''
        ..durationSeconds = map['durationSeconds'] ?? 0;
    }).toList();

    state = tracks;
  }

  Future<void> toggleFavorite(Track track) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];

    final index = state.indexWhere((t) => t.youtubeId == track.youtubeId);
    if (index >= 0) {
      // Remover de favoritos
      raw.removeAt(index);
      await prefs.setStringList(_key, raw);
      state = [...state]..removeAt(index);
    } else {
      // Agregar a favoritos
      final entry = jsonEncode({
        'id': track.youtubeId,
        'title': track.title,
        'artist': track.artist,
        'thumbnailUrl': track.thumbnailUrl,
        'durationSeconds': track.durationSeconds,
      });
      raw.insert(0, entry);
      await prefs.setStringList(_key, raw);
      state = [track, ...state];
    }
  }

  bool isFavorite(String youtubeId) {
    return state.any((t) => t.youtubeId == youtubeId);
  }
}
