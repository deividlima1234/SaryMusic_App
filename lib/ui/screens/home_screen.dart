import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/track.dart';
import '../../services/playback_manager.dart';
import '../../services/youtube_service.dart';
import '../../services/play_history_service.dart';
import '../../services/taste_analyzer.dart';
import '../providers/download_notifier.dart';
import 'library_screen.dart';
import '../widgets/track_tile.dart';

// ──────────────────────────────────────────────────────────────────
// Providers
// ──────────────────────────────────────────────────────────────────

/// Lista de recomendaciones personalizadas (artistas + géneros detectados)
final _recommendationItemsProvider =
    FutureProvider<List<RecommendationItem>>((ref) async {
  final analyzer = TasteAnalyzer(PlayHistoryService());
  return analyzer.getRecommendations(); // [] si no hay historial
});

/// Chip seleccionado (label del RecommendationItem)
final _selectedChipProvider = StateProvider<String?>((ref) => null);

/// Tracks para una query dada
final _tracksProvider =
    FutureProvider.family<List<Track>, String>((ref, query) {
  return ref.read(youtubeServiceProvider).searchTracks(query);
});

// ──────────────────────────────────────────────────────────────────
// HomeScreen
// ──────────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Carga no-bloqueante: si aún no está listo devuelve []
    final items = ref.watch(_recommendationItemsProvider).asData?.value ?? [];
    final selectedChip = ref.watch(_selectedChipProvider);
    final hasHistory = items.isNotEmpty;

    // Query activa: chip seleccionado o el primero de la lista
    final activeItem = items.isEmpty
        ? null
        : items.firstWhere(
            (i) => i.label == selectedChip,
            orElse: () => items.first,
          );

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // HEADER — siempre visible
          SliverToBoxAdapter(
            child: _Header(
              subtitle: hasHistory
                  ? 'Para ti: ${items.take(2).map((i) => i.label).join(' • ')}'
                  : 'Tu música, sin límites.',
            ),
          ),

          // CHIPS — solo si hay historial
          if (hasHistory)
            SliverToBoxAdapter(
              child: _Chips(
                items: items,
                selectedLabel: activeItem?.label,
                onSelect: (label) {
                  final current = ref.read(_selectedChipProvider);
                  ref.read(_selectedChipProvider.notifier).state =
                      current == label ? null : label;
                },
              ),
            ),

          // TÍTULO DE SECCIÓN
          if (hasHistory && activeItem != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      activeItem.isArtistBased
                          ? 'Más de ${_capitalize(activeItem.label)}'
                          : activeItem.label,
                      style: GoogleFonts.orbitron(
                        color: AppTheme.textMain,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _PersonalBadge(isArtist: activeItem.isArtistBased),
                  ],
                ),
              ),
            ),

          // LISTA O ESTADO VACÍO
          if (!hasHistory)
            const SliverFillRemaining(child: _EmptyState())
          else if (activeItem != null)
            _TrackListSliver(query: activeItem.query),

          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ──────────────────────────────────────────────────────────────────
// Widgets
// ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String subtitle;
  const _Header({required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                      colors: [Color(0xFFFF2A2A), Color(0xFF8B0000)]),
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.primary.withOpacity(0.5),
                        blurRadius: 14,
                        spreadRadius: 2)
                  ],
                ),
                child: Center(
                  child: Text('S',
                      style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 10),
              Text('SARY',
                  style: GoogleFonts.orbitron(
                      color: AppTheme.textMain,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4)),
              Text('MUSIC',
                  style: GoogleFonts.orbitron(
                      color: AppTheme.primary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4)),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle,
              style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  letterSpacing: 0.4)),
          const SizedBox(height: 20),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppTheme.primary.withOpacity(0.8),
                Colors.transparent,
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  final List<RecommendationItem> items;
  final String? selectedLabel;
  final void Function(String) onSelect;

  const _Chips(
      {required this.items,
      required this.selectedLabel,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final item = items[i];
          final isSelected =
              selectedLabel == item.label || (selectedLabel == null && i == 0);

          return GestureDetector(
            onTap: () => onSelect(item.label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: !isSelected
                    ? Border.all(
                        color: AppTheme.primary
                            .withOpacity(item.isArtistBased ? 0.5 : 0.15))
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: AppTheme.primary.withOpacity(0.4),
                            blurRadius: 8)
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.isArtistBased
                        ? Icons.person_rounded
                        : Icons.music_note_rounded,
                    size: 13,
                    color: isSelected ? Colors.white : AppTheme.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    item.label,
                    style: GoogleFonts.inter(
                      color: isSelected ? Colors.white : AppTheme.textMain,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PersonalBadge extends StatelessWidget {
  final bool isArtist;
  const _PersonalBadge({required this.isArtist});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isArtist ? Icons.favorite_rounded : Icons.auto_awesome_rounded,
            size: 11,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 3),
          Text(
            isArtist ? 'Favorito' : 'Para ti',
            style: GoogleFonts.inter(
                color: AppTheme.primary,
                fontSize: 10,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _TrackListSliver extends ConsumerWidget {
  final String query;
  const _TrackListSliver({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(_tracksProvider(query));
    return tracksAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 60),
          child:
              Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        ),
      ),
      error: (_, __) => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 60),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.wifi_off_rounded,
                    color: AppTheme.textSecondary, size: 40),
                SizedBox(height: 10),
                Text('Sin conexión',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ),
      ),
      data: (tracks) => SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final track = tracks[i];
            return TrackTile(
              track: track,
              onTap: () =>
                  ref.read(playbackManagerProvider).setQueueAndPlay(tracks, i),
              onDownload: track.localFilePath == null
                  ? () => _download(ref, ctx, track)
                  : null,
            );
          },
          childCount: tracks.length,
        ),
      ),
    );
  }

  void _download(WidgetRef ref, BuildContext context, Track track) async {
    final ytService = ref.read(youtubeServiceProvider);
    final dn = ref.read(downloadProvider.notifier);
    if (dn.isDownloading(track.youtubeId)) return;
    try {
      final info = await ytService.getStreamInfo(track.youtubeId);
      if (info == null) return;
      dn.setProgress(track.youtubeId, 0.01);
      final path = await ytService.downloadAudioPermanent(info, track.youtubeId,
          onProgress: (p) => dn.setProgress(track.youtubeId, p));
      track.localFilePath = path;
      dn.finish(track.youtubeId);
      ref.invalidate(downloadedTracksProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${track.title}" guardada ✔')));
      }
    } catch (_) {
      dn.finish(track.youtubeId);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.headphones_rounded,
                size: 72, color: AppTheme.primary.withOpacity(0.3)),
            const SizedBox(height: 20),
            Text('Escucha música',
                style: GoogleFonts.orbitron(
                    color: AppTheme.textMain,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(
              'Busca canciones o artistas y SaryMusic aprenderá tus gustos para mostrarte recomendaciones personalizadas.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
