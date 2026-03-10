import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final suggestionServiceProvider = Provider<SuggestionService>((ref) {
  return SuggestionService();
});

class SuggestionService {
  // API pública de autocompletado de YouTube (sin autenticación)
  // Retorna: ["query",[["sugerencia1",0],["sugerencia2",0],...]]
  static const _baseUrl =
      'https://suggestqueries.google.com/complete/search?client=firefox&ds=yt&hl=es&q=';

  Future<List<String>> getSuggestions(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse('$_baseUrl${Uri.encodeQueryComponent(query)}');
      final response = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0'
      }).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) return [];

      // Formato real: ["query", ["sug1", "sug2", ...], [], {...}]
      // decoded[1] es un array plano de strings
      final decoded = jsonDecode(response.body) as List<dynamic>;
      if (decoded.length < 2) return [];

      final suggestions = (decoded[1] as List<dynamic>)
          .whereType<String>() // cada elemento ya ES un String
          .take(7)
          .toList();

      return suggestions;
    } catch (e) {
      print('[SuggestionService] Error parseando respuesta: $e');
      return [];
    }
  }
}
