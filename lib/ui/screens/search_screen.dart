import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/track_tile.dart';
import '../providers/download_notifier.dart';
import '../providers/search_history_notifier.dart';
import 'search_view_model.dart';
import '../../services/youtube_service.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmit(String query) {
    if (query.isNotEmpty) {
      // Guardar en historial
      ref.read(searchHistoryProvider.notifier).add(query);
      ref.read(searchProvider.notifier).search(query);
    }
  }

  void _playTrack(Track track, List<Track> allTracks, int index) {
    // PlaybackManager centralizado maneja streaming, local y auto-avance
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
        onProgress: (progress) {
          downloadNotifier.setProgress(track.youtubeId, progress);
        },
      );

      track.localFilePath = filePath;
      await isarService.saveTrack(track);
      downloadNotifier.finish(track.youtubeId);
      ref.invalidate(downloadedTracksProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('"${track.title}" guardada en tu biblioteca ✔')),
        );
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
            // Campo de búsqueda
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: _onSearchSubmit,
                onChanged: (_) =>
                    setState(() {}), // Refrescar para mostrar historial
                style: const TextStyle(color: AppTheme.textMain),
                decoration: InputDecoration(
                  hintText: 'Buscar en YouTube...',
                  hintStyle: const TextStyle(color: AppTheme.textSecondary),
                  prefixIcon:
                      const Icon(Icons.search, color: AppTheme.textSecondary),
                  suffixIcon: IconButton(
                    icon:
                        const Icon(Icons.clear, color: AppTheme.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchProvider.notifier).clear();
                      setState(() {});
                    },
                  ),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            Expanded(
              child: searchState.when(
                data: (tracks) {
                  // Mostrar historial cuando campo vacío o sin resultados
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
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
                error: (error, _) => Center(
                  child: Text('Error: $error',
                      style: const TextStyle(color: AppTheme.primary)),
                ),
              ),
            ),
          ],
        ),
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
                onPressed: () {
                  ref.read(searchHistoryProvider.notifier).clearAll();
                },
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
                  onPressed: () {
                    ref.read(searchHistoryProvider.notifier).remove(term);
                  },
                ),
                onTap: () {
                  _searchController.text = term;
                  _onSearchSubmit(term);
                  setState(() {});
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
