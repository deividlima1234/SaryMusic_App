import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/database/isar_service.dart';
import '../../data/models/track.dart';
import '../../services/playback_manager.dart';
import '../widgets/track_tile.dart';

// Provider de canciones descargadas (FutureProvider que se puede refrescar)
final downloadedTracksProvider = FutureProvider<List<Track>>((ref) async {
  final isarService = ref.read(isarServiceProvider);
  return await isarService.getDownloadedTracks();
});

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(downloadedTracksProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Biblioteca Local',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textMain,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                'Canciones descargadas para escuchar sin internet',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ),
            Expanded(
              child: tracksAsync.when(
                data: (tracks) {
                  if (tracks.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.library_music_rounded,
                              size: 72, color: AppTheme.textSecondary),
                          SizedBox(height: 16),
                          Text('Aún no hay canciones',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 18)),
                          SizedBox(height: 8),
                          Text('Descarga pistas desde la búsqueda',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 13)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      return Dismissible(
                        key: Key(track.youtubeId),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          color: Colors.red.withOpacity(0.8),
                          child: const Icon(Icons.delete_rounded,
                              color: Colors.white, size: 28),
                        ),
                        onDismissed: (_) async {
                          if (track.localFilePath != null) {
                            final file = File(track.localFilePath!);
                            if (await file.exists()) await file.delete();
                          }
                          await ref
                              .read(isarServiceProvider)
                              .deleteTrack(track);
                          ref.invalidate(downloadedTracksProvider);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    '"${track.title}" eliminada de la biblioteca')));
                          }
                        },
                        child: TrackTile(
                          track: track,
                          onTap: () {
                            // ✅ Usar PlaybackManager con la lista completa de biblioteca
                            // Así el skip ⏭ navega solo por canciones descargadas
                            ref
                                .read(playbackManagerProvider)
                                .setQueueAndPlay(tracks, index);
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary)),
                error: (e, _) => Center(
                  child: Text('Error: $e',
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
