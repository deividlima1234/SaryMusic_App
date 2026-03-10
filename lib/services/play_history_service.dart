import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/track.dart';

/// Persiste el historial de reproducciones (últimas 50 pistas)
/// en SharedPreferences para análisis de gustos offline.
class PlayHistoryService {
  static const _key = 'play_history';
  static const _maxEntries = 50;

  Future<void> record(Track track) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];

    final entry = jsonEncode({
      'id': track.youtubeId,
      'title': track.title.toLowerCase(),
      'artist': track.artist.toLowerCase(),
      'thumbnailUrl': track.thumbnailUrl,
      'durationSeconds': track.durationSeconds,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });

    // Insertar al inicio, limitar a _maxEntries
    final updated = [entry, ...raw];
    await prefs.setStringList(_key, updated.take(_maxEntries).toList());
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
