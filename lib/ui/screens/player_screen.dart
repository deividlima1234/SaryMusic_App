import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/audio_player_service.dart';
import '../../services/playback_manager.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String title;
  final String artist;
  final String? thumbnailUrl;

  const PlayerScreen({
    super.key,
    required this.title,
    required this.artist,
    this.thumbnailUrl,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  double? _draggingValue;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _breathingAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration? d) {
    if (d == null || d == Duration.zero) return "0:00";
    String p(int n) => n.toString().padLeft(2, "0");
    return "${d.inHours > 0 ? '${d.inHours}:' : ''}${p(d.inMinutes.remainder(60))}:${p(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(audioPlayerServiceProvider);
    final manager = ref.read(playbackManagerProvider);

    return StreamBuilder<bool>(
      stream: audioService.player.playingStream,
      builder: (context, playSnap) {
        final isPlaying = playSnap.data ?? false;

        if (isPlaying && !_breathingController.isAnimating) {
          _breathingController.repeat(reverse: true);
        } else if (!isPlaying && _breathingController.isAnimating) {
          _breathingController.stop();
        }

        return StreamBuilder<Duration?>(
          stream: audioService.player.positionStream,
          builder: (context, posSnap) {
            return StreamBuilder<Duration?>(
              stream: audioService.player.durationStream,
              builder: (context, durSnap) {
                final position = posSnap.data ?? Duration.zero;
                final total = durSnap.data ?? Duration.zero;
                final totalMs = total.inMilliseconds.toDouble();
                final sliderValue = _draggingValue ??
                    (totalMs > 0
                        ? (position.inMilliseconds / totalMs).clamp(0.0, 1.0)
                        : 0.0);

                return Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.background,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle visual
                      Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(10))),
                      const SizedBox(height: 32),

                      // Cover Art animado
                      AnimatedBuilder(
                        animation: _breathingAnimation,
                        builder: (context, child) => Transform.scale(
                          scale: _breathingAnimation.value,
                          child: child,
                        ),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.75,
                          height: MediaQuery.of(context).size.width * 0.75,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: widget.thumbnailUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(widget.thumbnailUrl!),
                                    fit: BoxFit.cover)
                                : null,
                            boxShadow: isPlaying
                                ? [
                                    BoxShadow(
                                        color:
                                            AppTheme.primary.withOpacity(0.4),
                                        blurRadius: 40,
                                        spreadRadius: 10)
                                  ]
                                : [],
                            color: AppTheme.surface,
                          ),
                          child: widget.thumbnailUrl == null
                              ? const Icon(Icons.music_note,
                                  color: Colors.white, size: 80)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Título y artista
                      Text(widget.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(color: AppTheme.textMain)),
                      const SizedBox(height: 8),
                      Text(widget.artist,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: AppTheme.textSecondary)),
                      const SizedBox(height: 24),

                      // ── SEEK SLIDER ──
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppTheme.primary,
                          inactiveTrackColor: Colors.white12,
                          thumbColor: AppTheme.primary,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7),
                          overlayShape:
                              const RoundSliderOverlayShape(overlayRadius: 18),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          min: 0.0,
                          max: 1.0,
                          value: sliderValue,
                          onChangeStart: (v) =>
                              setState(() => _draggingValue = v),
                          onChanged: (v) => setState(() => _draggingValue = v),
                          onChangeEnd: (v) {
                            if (totalMs > 0) {
                              audioService.seek(Duration(
                                  milliseconds: (v * totalMs).toInt()));
                            }
                            setState(() => _draggingValue = null);
                          },
                        ),
                      ),

                      // Tiempos
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(position),
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12)),
                            Text(_formatDuration(total),
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── CONTROLES ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Anterior
                          IconButton(
                            icon: Icon(Icons.skip_previous_rounded,
                                size: 48,
                                color: manager.hasPrevious
                                    ? AppTheme.textMain
                                    : AppTheme.textSecondary),
                            onPressed: () => manager.skipToPrevious(),
                          ),

                          // Play / Pause
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: isPlaying
                                  ? [
                                      BoxShadow(
                                          color:
                                              AppTheme.primary.withOpacity(0.5),
                                          blurRadius: 20,
                                          spreadRadius: 2)
                                    ]
                                  : [],
                            ),
                            child: IconButton(
                              icon: Icon(
                                  isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  size: 80,
                                  color: isPlaying
                                      ? AppTheme.primary
                                      : AppTheme.textMain),
                              onPressed: () {
                                if (isPlaying) {
                                  audioService.pause();
                                } else {
                                  audioService.resume();
                                }
                              },
                            ),
                          ),

                          // Siguiente
                          IconButton(
                            icon: Icon(Icons.skip_next_rounded,
                                size: 48,
                                color: manager.hasNext
                                    ? AppTheme.textMain
                                    : AppTheme.textSecondary),
                            onPressed: () => manager.skipToNext(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
