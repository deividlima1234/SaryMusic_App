import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/database/isar_service.dart';
import '../../data/models/playlist.dart';
import '../../services/playback_manager.dart';
import '../widgets/track_tile.dart';

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final int playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  ConsumerState<PlaylistDetailScreen> createState() =>
      _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  Playlist? _playlist;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    final isar = await ref.read(isarServiceProvider).db;
    final playlist = await isar.playlists.get(widget.playlistId);
    if (mounted) {
      setState(() {
        _playlist = playlist;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_playlist == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(backgroundColor: AppTheme.background),
        body: const Center(
            child: Text('Playlist no encontrada',
                style: TextStyle(color: Colors.white))),
      );
    }

    final tracks = _playlist!.tracks.toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppTheme.background,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _playlist!.name,
                style: GoogleFonts.orbitron(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primary.withOpacity(0.5),
                      AppTheme.background,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                      _playlist!.isLocal
                          ? Icons.folder_rounded
                          : Icons.wifi_tethering_rounded,
                      size: 80,
                      color: Colors.white24),
                ),
              ),
            ),
          ),
          if (tracks.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('Esta playlist está vacía',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = tracks[index];
                  return TrackTile(
                    track: track,
                    onTap: () {
                      ref
                          .read(playbackManagerProvider)
                          .setQueueAndPlay(tracks, index);
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded,
                          color: Colors.redAccent),
                      onPressed: () async {
                        await ref
                            .read(isarServiceProvider)
                            .removeTrackFromPlaylist(_playlist!.id, track.id);
                        _loadPlaylist();
                      },
                    ),
                  );
                },
                childCount: tracks.length,
              ),
            ),
        ],
      ),
      floatingActionButton: tracks.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                ref.read(playbackManagerProvider).setQueueAndPlay(tracks, 0);
              },
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 30),
            )
          : null,
    );
  }
}
