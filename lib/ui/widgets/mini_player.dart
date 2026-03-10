import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/track.dart';
import '../screens/player_screen.dart';
import '../providers/queue_notifier.dart';
import '../../services/audio_player_service.dart';
import '../../services/playback_manager.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioPlayerServiceProvider);
    final manager = ref.read(playbackManagerProvider);
    final queueState = ref.watch(queueProvider);

    // Escuchar el stream de playingStream para el botón play/pause
    return StreamBuilder<bool>(
        stream: audioService.player.playingStream,
        builder: (context, playingSnapshot) {
          // Escuchar currentTrackStream del manager para metadata inmediata
          return StreamBuilder<Track?>(
              stream: manager.currentTrackStream,
              initialData: manager.currentTrack,
              builder: (context, trackSnapshot) {
                final currentTrack = trackSnapshot.data;

                // Fallback: si no hay track en el manager, verificar sequenceState
                return StreamBuilder<Object?>(
                    stream: audioService.player.sequenceStateStream
                        .map((s) => s?.currentSource?.tag),
                    builder: (context, tagSnapshot) {
                      final isPlaying = playingSnapshot.data ?? false;

                      // Resolver título e imagen: prioridad al track del manager
                      final String title;
                      final String artist;
                      final String? thumbnailUrl;

                      if (currentTrack != null) {
                        title = currentTrack.title;
                        artist = currentTrack.artist;
                        thumbnailUrl = currentTrack.thumbnailUrl.isNotEmpty
                            ? currentTrack.thumbnailUrl
                            : null;
                      } else {
                        final tag = tagSnapshot.data as MediaItem?;
                        title = tag?.title ?? '';
                        artist = tag?.artist ?? '';
                        thumbnailUrl = tag?.artUri?.toString();
                      }

                      // Ocultar si no hay nada que mostrar
                      if (title.isEmpty) return const SizedBox.shrink();

                      return GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            barrierColor: Colors.black87,
                            builder: (context) => PlayerScreen(
                              title: title,
                              artist: artist,
                              thumbnailUrl: thumbnailUrl,
                            ),
                          );
                        },
                        child: Container(
                          height: 65,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surface.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isPlaying
                                  ? AppTheme.primary.withOpacity(0.5)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                            boxShadow: isPlaying
                                ? [
                                    BoxShadow(
                                        color:
                                            AppTheme.primary.withOpacity(0.2),
                                        blurRadius: 15,
                                        spreadRadius: 1)
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              // Cover Art
                              Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22.5),
                                  image: thumbnailUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(thumbnailUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  color: Colors.grey[800],
                                ),
                                child: thumbnailUrl == null
                                    ? const Icon(Icons.music_note,
                                        color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textMain,
                                            )),
                                    Text(artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ],
                                ),
                              ),
                              // Play/Pause
                              IconButton(
                                icon: Icon(
                                  isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  size: 36,
                                  color: isPlaying
                                      ? AppTheme.primary
                                      : AppTheme.textMain,
                                ),
                                onPressed: () {
                                  if (isPlaying) {
                                    audioService.pause();
                                  } else {
                                    audioService.resume();
                                  }
                                },
                              ),
                              // Skip next
                              if (manager.hasNext)
                                IconButton(
                                  icon: const Icon(Icons.skip_next_rounded,
                                      size: 28, color: AppTheme.textSecondary),
                                  onPressed: () => ref
                                      .read(playbackManagerProvider)
                                      .skipToNext(),
                                ),
                            ],
                          ),
                        ),
                      );
                    });
              });
        });
  }
}
