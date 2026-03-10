import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/track_tile.dart';
import '../providers/download_notifier.dart';
import '../providers/search_history_notifier.dart';
import 'search_view_model.dart';
import '../../services/youtube_service.dart';
import '../../services/suggestion_service.dart';
import '../../services/playback_manager.dart';
import '../../data/database/isar_service.dart';
import '../../data/models/track.dart';
import 'library_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Estado de sugerencias
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        // Mostrar sugerencias solo si el campo tiene foco y hay texto
        _showSuggestions =
            _focusNode.hasFocus && _searchController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String query) {
    setState(() {}); // Refrescar UI inmediatamente (botón clear, etc.)
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    // Debounce de 350ms
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      print('[Suggestions] Pidiendo sugerencias para: $query');
      final results =
          await ref.read(suggestionServiceProvider).getSuggestions(query);
      print('[Suggestions] Recibidas: ${results.length} → $results');
      if (mounted) {
        setState(() {
          _suggestions = results;
          _showSuggestions = results.isNotEmpty;
        });
      }
    });
  }

  void _onSearchSubmit(String query) {
    if (query.isEmpty) return;
    _focusNode.unfocus();
    setState(() => _showSuggestions = false);
    ref.read(searchHistoryProvider.notifier).add(query);
    ref.read(searchProvider.notifier).search(query);
  }

  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _onSearchSubmit(suggestion);
  }

  void _playTrack(Track track, List<Track> allTracks, int index) {
    ref.read(playbackManagerProvider).setQueueAndPlay(allTracks, index);
  }

  void _downloadTrack(Track track) async {
    final ytService = ref.read(youtubeServiceProvider);
    final isarService = ref.read(isarServiceProvider);
    final downloadNotifier = ref.read(downloadProvider.notifier);

    if (downloadNotifier.isDownloading(track.youtubeId)) return;

    try {
      final streamInfo = await ytService.getStreamInfo(track.youtubeId);
      if (streamInfo == null) return;

      downloadNotifier.setProgress(track.youtubeId, 0.01);

      final filePath = await ytService.downloadAudioPermanent(
        streamInfo,
        track.youtubeId,
        onProgress: (p) => downloadNotifier.setProgress(track.youtubeId, p),
      );

      track.localFilePath = filePath;
      await isarService.saveTrack(track);
      downloadNotifier.finish(track.youtubeId);
      ref.invalidate(downloadedTracksProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('"${track.title}" guardada en la biblioteca ✔')));
      }
    } catch (e) {
      downloadNotifier.finish(track.youtubeId);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al descargar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final history = ref.watch(searchHistoryProvider);
    final isSearchEmpty = _searchController.text.isEmpty;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Campo de búsqueda con overlay de sugerencias
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  // TextField
                  TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _onSearchSubmit,
                    onChanged: _onTextChanged,
                    style: const TextStyle(color: AppTheme.textMain),
                    decoration: InputDecoration(
                      hintText: 'Buscar artista, canción o álbum...',
                      hintStyle: const TextStyle(color: AppTheme.textSecondary),
                      prefixIcon: const Icon(Icons.search,
                          color: AppTheme.textSecondary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: AppTheme.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(searchProvider.notifier).clear();
                                setState(() {
                                  _suggestions = [];
                                  _showSuggestions = false;
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),

                  // Overlay de sugerencias
                  if (_showSuggestions && _suggestions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _buildSuggestionsOverlay(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: searchState.when(
                data: (tracks) {
                  if (tracks.isEmpty && isSearchEmpty && history.isNotEmpty) {
                    return _buildHistory(history);
                  }
                  if (tracks.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.satellite_alt_rounded,
                              size: 64, color: AppTheme.textSecondary),
                          SizedBox(height: 16),
                          Text('Señal no identificada',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 18)),
                        ],
                      ),
                    );
                  }
                  return _buildTrackList(tracks);
                },
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary)),
                error: (error, _) => Center(
                    child: Text('Error: $error',
                        style: const TextStyle(color: AppTheme.primary))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsOverlay() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_suggestions.length, (i) {
          final s = _suggestions[i];
          final query = _searchController.text.toLowerCase();

          return InkWell(
            borderRadius: BorderRadius.vertical(
              top: i == 0 ? const Radius.circular(16) : Radius.zero,
              bottom: i == _suggestions.length - 1
                  ? const Radius.circular(16)
                  : Radius.zero,
            ),
            onTap: () => _selectSuggestion(s),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.search,
                      size: 18, color: AppTheme.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHighlightedText(s, query),
                  ),
                  const Icon(Icons.north_west,
                      size: 16, color: AppTheme.textSecondary),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Resalta en negrita la parte que ya escribió el usuario
  Widget _buildHighlightedText(String suggestion, String query) {
    final lower = suggestion.toLowerCase();
    final matchStart = lower.indexOf(query);
    if (matchStart == -1 || query.isEmpty) {
      return Text(suggestion, style: const TextStyle(color: AppTheme.textMain));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(color: AppTheme.textMain, fontSize: 14),
        children: [
          if (matchStart > 0)
            TextSpan(text: suggestion.substring(0, matchStart)),
          TextSpan(
            text: suggestion.substring(matchStart, matchStart + query.length),
            style: const TextStyle(
                color: AppTheme.primary, fontWeight: FontWeight.bold),
          ),
          TextSpan(text: suggestion.substring(matchStart + query.length)),
        ],
      ),
    );
  }

  Widget _buildHistory(List<String> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Búsquedas recientes',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.textSecondary)),
              TextButton(
                onPressed: () =>
                    ref.read(searchHistoryProvider.notifier).clearAll(),
                child: const Text('Borrar todo',
                    style: TextStyle(color: AppTheme.primary, fontSize: 12)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final term = history[index];
              return ListTile(
                leading: const Icon(Icons.history_rounded,
                    color: AppTheme.textSecondary),
                title: Text(term,
                    style: const TextStyle(color: AppTheme.textMain)),
                trailing: IconButton(
                  icon: const Icon(Icons.close,
                      color: AppTheme.textSecondary, size: 18),
                  onPressed: () =>
                      ref.read(searchHistoryProvider.notifier).remove(term),
                ),
                onTap: () {
                  _searchController.text = term;
                  _onSearchSubmit(term);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrackList(List<Track> tracks) {
    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return TrackTile(
          track: track,
          onTap: () => _playTrack(track, tracks, index),
          onDownload:
              track.localFilePath == null ? () => _downloadTrack(track) : null,
        );
      },
    );
  }
}
