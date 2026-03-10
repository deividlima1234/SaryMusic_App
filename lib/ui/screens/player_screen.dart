import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/audio_player_service.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String title;
  final String artist;
  final String? thumbnailUrl;
  final bool isPlaying;

  const PlayerScreen({
    super.key,
    required this.title,
    required this.artist,
    this.thumbnailUrl,
    required this.isPlaying,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _breathingAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    if (widget.isPlaying) {
      _breathingController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_breathingController.isAnimating) {
      _breathingController.repeat(reverse: true);
    } else if (!widget.isPlaying && _breathingController.isAnimating) {
      _breathingController.stop();
      _breathingController.animateTo(0.5); // Regresar al centro
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return "0:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${duration.inHours}:' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(audioPlayerServiceProvider);

    return StreamBuilder<Duration?>(
        stream: audioService.player.positionStream,
        builder: (context, positionSnapshot) {
          return StreamBuilder<Duration?>(
              stream: audioService.player.durationStream,
              builder: (context, durationSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                final totalDuration = durationSnapshot.data ?? Duration.zero;

                double progress = 0.0;
                if (totalDuration.inMilliseconds > 0) {
                  progress =
                      position.inMilliseconds / totalDuration.inMilliseconds;
                }

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
                      Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(10))),
                      const SizedBox(height: 32),

                      // Cover Art Respirando
                      AnimatedBuilder(
                        animation: _breathingAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _breathingAnimation.value,
                            child: child,
                          );
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.75,
                          height: MediaQuery.of(context).size.width * 0.75,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: widget.thumbnailUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(widget.thumbnailUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            boxShadow: widget.isPlaying
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
                      const SizedBox(height: 48),

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

                      const SizedBox(height: 32),

                      // Barra de Progreso Custom Asimétrica
                      Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                              height: 4,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(2))),
                          FractionallySizedBox(
                            widthFactor: progress.clamp(0.0, 1.0),
                            child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [
                                      AppTheme.primary,
                                      Colors.redAccent
                                    ]),
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: AppTheme.primary,
                                          blurRadius: 8,
                                          spreadRadius: 1)
                                    ])),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(position),
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12)),
                          Text(_formatDuration(totalDuration),
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),

                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.skip_previous_rounded,
                                  size: 48, color: AppTheme.textMain),
                              onPressed: () {}),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: widget.isPlaying
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
                                  widget.isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  size: 80,
                                  color: widget.isPlaying
                                      ? AppTheme.primary
                                      : AppTheme.textMain),
                              onPressed: () {
                                if (widget.isPlaying) {
                                  audioService.pause();
                                } else {
                                  audioService.resume();
                                }
                              },
                            ),
                          ),
                          IconButton(
                              icon: const Icon(Icons.skip_next_rounded,
                                  size: 48, color: AppTheme.textMain),
                              onPressed: () {}),
                        ],
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                );
              });
        });
  }
}
