import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/track.dart';
import '../../services/playback_manager.dart';
import '../providers/download_notifier.dart';

/// Widget de barra animada "Now Playing"
class _NowPlayingBars extends StatefulWidget {
  const _NowPlayingBars();

  @override
  State<_NowPlayingBars> createState() => _NowPlayingBarsState();
}

class _NowPlayingBarsState extends State<_NowPlayingBars>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    final delays = [0, 150, 300];
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + i * 100),
      )..repeat(reverse: true),
    );

    _animations = List.generate(
      3,
      (i) => Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(parent: _controllers[i], curve: Curves.easeInOut),
      ),
    );

    // Desfasar las barras para que no sean síncronas
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: delays[i]), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, _) => Container(
            width: 3,
            height: 14 * _animations[i].value,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class TrackTile extends ConsumerWidget {
  final Track track;
  final VoidCallback onTap;
  final VoidCallback? onDownload;

  const TrackTile({
    super.key,
    required this.track,
    required this.onTap,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(downloadProvider);
    final isDownloading = downloadState.containsKey(track.youtubeId);
    final progress = downloadState[track.youtubeId] ?? 0.0;
    final isDownloaded = track.localFilePath != null;

    return StreamBuilder<Track?>(
      stream: ref.read(playbackManagerProvider).currentTrackStream,
      initialData: ref.read(playbackManagerProvider).currentTrack,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data?.youtubeId == track.youtubeId;

        return StreamBuilder<bool>(
          stream: ref.read(playbackManagerProvider).isBufferingStream,
          initialData: false,
          builder: (context, bufferingSnapshot) {
            final isBuffering = bufferingSnapshot.data ?? false;

            return InkWell(
              onTap: onTap,
              splashColor: AppTheme.primary.withOpacity(0.2),
              highlightColor: AppTheme.surface,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isPlaying
                      ? AppTheme.primary.withOpacity(0.07)
                      : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Thumbnail / Now Playing indicator
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: track.thumbnailUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(track.thumbnailUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: AppTheme.surface,
                      ),
                      child: track.thumbnailUrl.isEmpty
                          ? const Icon(Icons.music_note,
                              color: AppTheme.textSecondary)
                          : null,
                    ),
                    const SizedBox(width: 16),

                    // Textos + Now Playing / Loading label
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isPlaying)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Row(
                                children: [
                                  if (isBuffering)
                                    const SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primary,
                                      ),
                                    )
                                  else
                                    const _NowPlayingBars(),
                                  const SizedBox(width: 6),
                                  Text(
                                    isBuffering
                                        ? 'Cargando...'
                                        : 'Reproduciendo',
                                    style: TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: isPlaying
                                          ? AppTheme.primary
                                          : AppTheme.textMain,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Icono de estado de descarga
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: _buildDownloadWidget(
                          isDownloaded, isDownloading, progress),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDownloadWidget(
      bool isDownloaded, bool isDownloading, double progress) {
    if (isDownloaded) {
      return const Icon(Icons.check_circle_rounded,
          color: AppTheme.primary, size: 24);
    }
    if (isDownloading) {
      return Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 2,
            color: AppTheme.primary,
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.bold),
          ),
        ],
      );
    }
    if (onDownload != null) {
      return IconButton(
        icon: const Icon(Icons.download_rounded, color: AppTheme.textSecondary),
        onPressed: onDownload,
      );
    }
    return const SizedBox.shrink();
  }
}
