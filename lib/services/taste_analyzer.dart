import '../data/models/track.dart';
import 'play_history_service.dart';

/// Analiza el historial de reproducciones para generar recomendaciones
/// basadas en los artistas y estilos reales del usuario.
class TasteAnalyzer {
  final PlayHistoryService _history;
  TasteAnalyzer(this._history);

  // ── Detección de géneros por palabras clave ────────────────────
  static const _genreKeywords = <String, List<String>>{
    'Reggaeton': [
      'bad bunny',
      'j balvin',
      'karol g',
      'ozuna',
      'daddy yankee',
      'maluma',
      'nicky jam',
      'anuel',
      'myke towers',
      'sech',
      'jhay cortez',
      'rauw alejandro',
      'lunay',
      'reggaeton',
      'dembow',
      'wisin',
      'yandel',
    ],
    'Trap Latino': [
      'trap',
      'arcangel',
      'de la ghetto',
      'flow',
      'eladio carrion',
      'mora',
      'quevedo',
      'bizarrap',
      'bzrp',
    ],
    'Pop Latino': [
      'shakira',
      'enrique iglesias',
      'marc anthony',
      'ricky martin',
      'camila cabello',
      'luis fonsi',
      'carlos vives',
      'becky g',
      'natti natasha',
      'sebastian yatra',
    ],
    'Rock': [
      'rock',
      'nirvana',
      'metallica',
      'acdc',
      'led zeppelin',
      'queen',
      'beatles',
      'radiohead',
      'foo fighters',
      'linkin park',
      'guns n roses',
      'coldplay',
      'u2',
      'rolling stones',
      'metal',
      'alternative',
    ],
    'Pop': [
      'taylor swift',
      'ariana grande',
      'ed sheeran',
      'billie eilish',
      'dua lipa',
      'harry styles',
      'bts',
      'olivia rodrigo',
      'the weeknd',
      'justin bieber',
      'selena gomez',
      'adele',
      'post malone',
    ],
    'Electrónica': [
      'electronic',
      'dj',
      'edm',
      'house',
      'techno',
      'trance',
      'martin garrix',
      'tiesto',
      'avicii',
      'deadmau5',
      'skrillex',
      'calvin harris',
      'david guetta',
      'marshmello',
      'remix',
    ],
    'Jazz': [
      'jazz',
      'blues',
      'soul',
      'frank sinatra',
      'miles davis',
      'saxophone',
      'trumpet',
      'swing',
      'bebop',
    ],
    'Salsa & Tropical': [
      'salsa',
      'merengue',
      'cumbia',
      'bachata',
      'celia cruz',
      'willie colon',
      'hector lavoe',
      'romeo santos',
      'aventura',
      'tropical',
    ],
    'Hip-Hop': [
      'hip hop',
      'rap',
      'drake',
      'kendrick lamar',
      'eminem',
      'jay-z',
      'kanye',
      'lil wayne',
      'nicki minaj',
      'cardi b',
      'travis scott',
    ],
    'Lofi & Chill': [
      'lofi',
      'lo-fi',
      'chill',
      'relaxing',
      'study',
      'beats',
      'ambient',
      'bossa nova',
      'smooth',
    ],
  };

  /// Devuelve las pistas más reproducidas (basadas en frecuencia)
  Future<List<Track>> getMostPlayedTracks({int limit = 10}) async {
    final history = await _history.getHistory();
    if (history.isEmpty) return [];

    final freq = <String, int>{};
    final trackMap = <String, Track>{};

    for (final e in history) {
      final id = e['id'] as String?;
      if (id == null) continue;

      freq[id] = (freq[id] ?? 0) + 1;

      if (!trackMap.containsKey(id)) {
        trackMap[id] = Track()
          ..youtubeId = id
          ..title = e['title'] ?? 'Desconocido'
          ..artist = e['artist'] ?? 'Desconocido'
          ..thumbnailUrl = e['thumbnailUrl'] ?? ''
          ..durationSeconds = e['durationSeconds'] ?? 0;
      }
    }

    // Ordenar de mayor a menor frecuencia
    final sortedIds = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Mapear los ids ordenados a sus respectivos Tracks
    return sortedIds.take(limit).map((e) => trackMap[e.key]!).toList();
  }

  /// Extrae los artistas más reproducidos del historial.
  Future<List<String>> getTopArtists({int limit = 5}) async {
    final history = await _history.getHistory();
    if (history.isEmpty) return [];

    final freq = <String, int>{};
    for (final e in history) {
      final artist = (e['artist'] as String? ?? '').trim();
      if (artist.isNotEmpty && artist != 'desconocido' && artist != 'unknown') {
        freq[artist] = (freq[artist] ?? 0) + 1;
      }
    }

    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Géneros más escuchados (sin fallback si no hay historial).
  Future<List<String>> getTopGenres({int limit = 3}) async {
    final history = await _history.getHistory();
    if (history.isEmpty) return []; // ← SIN fallback hardcodeado

    final scores = <String, int>{};
    for (final e in history) {
      final text = '${e['title'] ?? ''} ${e['artist'] ?? ''}'.toLowerCase();
      for (final genre in _genreKeywords.keys) {
        for (final kw in _genreKeywords[genre]!) {
          if (text.contains(kw)) {
            scores[genre] = (scores[genre] ?? 0) + 1;
          }
        }
      }
    }

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Genera queries de búsqueda en YouTube para recomendaciones.
  /// Prioridad: artistas más escuchados → géneros → vacío.
  Future<List<RecommendationItem>> getRecommendations() async {
    final results = <RecommendationItem>[];

    final artists = await getTopArtists(limit: 4);
    for (final artist in artists) {
      results.add(RecommendationItem(
        label: artist,
        query: '$artist mix', // busca playlist/mix del artista
        isArtistBased: true,
      ));
    }

    final genres = await getTopGenres(limit: 2);
    for (final genre in genres) {
      if (!results.any((r) => r.label == genre)) {
        results.add(RecommendationItem(
          label: genre,
          query: '$genre hits',
          isArtistBased: false,
        ));
      }
    }

    return results;
  }
}

class RecommendationItem {
  final String label;
  final String query;
  final bool isArtistBased;

  const RecommendationItem({
    required this.label,
    required this.query,
    required this.isArtistBased,
  });
}
