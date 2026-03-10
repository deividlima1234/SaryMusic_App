import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../core/theme/app_theme.dart';
import '../screens/player_screen.dart';
import '../../services/audio_player_service.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioPlayerServiceProvider);

    return StreamBuilder<SequenceState?>(
        stream: audioService.player.sequenceStateStream,
        builder: (context, sequenceSnapshot) {
          if (sequenceSnapshot.data?.currentSource == null) {
            return const SizedBox
                .shrink(); // Ocultar si no hay nada cargado en el reproductor
          }

          return StreamBuilder<bool>(
              stream: audioService.player.playingStream,
              builder: (context, playingSnapshot) {
                final isPlaying = playingSnapshot.data ?? false;

                // Extraer metadatos de la etiqueta MediaItem
                final mediaItem =
                    sequenceSnapshot.data?.currentSource?.tag as MediaItem?;
                final title = mediaItem?.title ?? "Reproduciendo Audio";
                final artist = mediaItem?.artist ?? "Streaming";
                final String? thumbnailUrl = mediaItem?.artUri?.toString();

                return GestureDetector(
                  onTap: () {
                    // Expandir a Full Screen Player
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      barrierColor: Colors.black87,
                      builder: (context) => PlayerScreen(
                        title: title,
                        artist: artist,
                        thumbnailUrl: thumbnailUrl,
                        isPlaying: isPlaying,
                      ),
                    );
                  },
                  child: Container(
                    height: 65,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                  color: AppTheme.primary.withOpacity(0.2),
                                  blurRadius: 15,
                                  spreadRadius: 1)
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Cover Art en Mini
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
                        // Textos
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textMain,
                                    ),
                              ),
                              Text(
                                artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        // Controles
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
                      ],
                    ),
                  ),
                );
              });
        });
  }
}
