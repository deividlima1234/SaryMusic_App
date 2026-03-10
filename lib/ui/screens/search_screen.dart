import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/track_tile.dart';
import '../providers/download_notifier.dart';
import 'search_view_model.dart';
import '../../services/youtube_service.dart';
import '../../services/audio_player_service.dart';
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
      ref.read(searchProvider.notifier).search(query);
    }
  }

  void _playTrack(Track track) async {
    try {
      final audioService = ref.read(audioPlayerServiceProvider);

      // Si ya está descargada localmente, reproducir sin internet
      if (track.localFilePath != null) {
        await audioService.playLocal(track, track.localFilePath!);
        return;
      }

      final ytService = ref.read(youtubeServiceProvider);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Cargando audio...')));
      }

      final streamInfo = await ytService.getStreamInfo(track.youtubeId);

      if (streamInfo != null) {
        ytService.downloadAudioProgressive(
          streamInfo,
          track.youtubeId,
          onBufferReady: (filePath) async {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reproduciendo Audio')));
              await audioService.playStream(track, filePath);
            }
          },
        ).catchError((e) {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _downloadTrack(Track track) async {
    final ytService = ref.read(youtubeServiceProvider);
    final isarService = ref.read(isarServiceProvider);
    final downloadNotifier = ref.read(downloadProvider.notifier);

    // Evitar doble descarga
    if (downloadNotifier.isDownloading(track.youtubeId)) return;

    try {
      final streamInfo = await ytService.getStreamInfo(track.youtubeId);
      if (streamInfo == null) return;

      downloadNotifier.setProgress(track.youtubeId, 0.01); // Inicia el spinner

      final filePath = await ytService.downloadAudioPermanent(
        streamInfo,
        track.youtubeId,
        onProgress: (progress) {
          downloadNotifier.setProgress(track.youtubeId, progress);
        },
      );

      // Guardar en Isar con la ruta local
      track.localFilePath = filePath;
      await isarService.saveTrack(track);

      downloadNotifier.finish(track.youtubeId);

      // Refrescar la lista de biblioteca
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

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: _onSearchSubmit,
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
                  return ListView.builder(
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      return TrackTile(
                        track: track,
                        onTap: () => _playTrack(track),
                        onDownload: track.localFilePath == null
                            ? () => _downloadTrack(track)
                            : null,
                      );
                    },
                  );
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
}
