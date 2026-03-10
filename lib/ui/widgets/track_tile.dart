import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/track.dart';
import '../providers/download_notifier.dart';

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

    return InkWell(
      onTap: onTap,
      splashColor: AppTheme.primary.withOpacity(0.2),
      highlightColor: AppTheme.surface,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
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
                  ? const Icon(Icons.music_note, color: AppTheme.textSecondary)
                  : null,
            ),
            const SizedBox(width: 16),

            // Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDownloaded
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
              child:
                  _buildDownloadWidget(isDownloaded, isDownloading, progress),
            ),
          ],
        ),
      ),
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
