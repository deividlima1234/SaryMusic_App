import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/database/isar_service.dart';
import '../../data/models/playlist.dart';
import '../../data/models/track.dart';
import '../../services/playback_manager.dart';
import '../widgets/track_tile.dart';

// Providers reactivos (Streams para tiempo real)
final downloadedTracksProvider = StreamProvider<List<Track>>((ref) {
  final isarService = ref.read(isarServiceProvider);
  return isarService.watchDownloadedTracks();
});

final onlinePlaylistsProvider = StreamProvider<List<Playlist>>((ref) {
  final isarService = ref.read(isarServiceProvider);
  return isarService.watchPlaylists(local: false);
});

final localPlaylistsProvider = StreamProvider<List<Playlist>>((ref) {
  final isarService = ref.read(isarServiceProvider);
  return isarService.watchPlaylists(local: true);
});

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _createNewPlaylist(bool isLocal) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          isLocal ? 'Nueva Playlist Local' : 'Nueva Playlist Online',
          style: GoogleFonts.orbitron(color: Colors.white, fontSize: 18),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Nombre de la playlist',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final playlist = Playlist()
                  ..name = nameController.text.trim()
                  ..isLocal = isLocal;
                await ref.read(isarServiceProvider).savePlaylist(playlist);
                ref.invalidate(
                    isLocal ? localPlaylistsProvider : onlinePlaylistsProvider);
                if (mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        toolbarHeight: 0, // Ocultar toolbar para usar custom layout
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle:
              GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'CONEXIÓN', icon: Icon(Icons.wifi_rounded)),
            Tab(text: 'LOCAL', icon: Icon(Icons.folder_rounded)),
            Tab(
                text: 'DESCARGAS',
                icon: Icon(Icons.download_for_offline_rounded)),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(downloadedTracksProvider);
          ref.invalidate(onlinePlaylistsProvider);
          ref.invalidate(localPlaylistsProvider);
        },
        color: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        child: TabBarView(
          controller: _tabController,
          children: [
            _PlaylistListTab(isLocal: false),
            _PlaylistListTab(isLocal: true),
            const _DownloadsTab(),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
            bottom: 110.0), // Elevación para evitar solapamiento
        child: FloatingActionButton(
          onPressed: () {
            if (_tabController.index == 2) {
              // Ir a búsqueda si está en descargas? o simplemente nada
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content:
                      Text('Descarga música desde la pestaña de búsqueda')));
            } else {
              _createNewPlaylist(_tabController.index == 1);
            }
          },
          backgroundColor: AppTheme.primary,
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

class _PlaylistListTab extends ConsumerWidget {
  final bool isLocal;
  const _PlaylistListTab({required this.isLocal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync =
        ref.watch(isLocal ? localPlaylistsProvider : onlinePlaylistsProvider);

    return playlistsAsync.when(
      data: (playlists) {
        if (playlists.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        isLocal
                            ? Icons.folder_open_rounded
                            : Icons.cloud_off_rounded,
                        size: 64,
                        color: Colors.white24),
                    const SizedBox(height: 16),
                    Text(
                      isLocal
                          ? 'No tienes playlists locales'
                          : 'No tienes playlists online',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return ListView.builder(
          itemCount: playlists.length,
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                    isLocal
                        ? Icons.library_music_rounded
                        : Icons.wifi_tethering_rounded,
                    color: AppTheme.primary),
              ),
              title: Text(playlist.name,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text('${playlist.tracks.length} canciones',
                  style: const TextStyle(color: AppTheme.textSecondary)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textSecondary),
              onTap: () {
                context.push('/playlist/${playlist.id}');
              },
            );
          },
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary)),
      error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
    );
  }
}

class _DownloadsTab extends ConsumerWidget {
  const _DownloadsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(downloadedTracksProvider);

    return tracksAsync.when(
      data: (tracks) {
        if (tracks.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
              const Center(
                child: Text('Nada descargado aún',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
            ],
          );
        }
        return ListView.builder(
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            return TrackTile(
              track: track,
              onTap: () {
                ref
                    .read(playbackManagerProvider)
                    .setQueueAndPlay(tracks, index);
              },
              // Opción para agregar a playlist local
              trailing: IconButton(
                icon: const Icon(Icons.playlist_add_rounded,
                    color: AppTheme.primary),
                onPressed: () => _showAddToPlaylistDialog(context, ref, track),
              ),
            );
          },
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary)),
      error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
    );
  }

  void _showAddToPlaylistDialog(
      BuildContext context, WidgetRef ref, Track track) async {
    final playlists =
        await ref.read(isarServiceProvider).getPlaylists(local: true);

    if (context.mounted) {
      if (playlists.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Crea primero una Playlist Local')));
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Añadir a Playlist Local',
                  style:
                      GoogleFonts.orbitron(color: Colors.white, fontSize: 16)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: playlists.length,
                itemBuilder: (c, i) => ListTile(
                  leading: const Icon(Icons.playlist_add_rounded,
                      color: AppTheme.primary),
                  title: Text(playlists[i].name,
                      style: const TextStyle(color: Colors.white)),
                  onTap: () async {
                    await ref
                        .read(isarServiceProvider)
                        .addTrackToPlaylist(playlists[i].id, track);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Añadido a ${playlists[i].name}')));
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    }
  }
}
