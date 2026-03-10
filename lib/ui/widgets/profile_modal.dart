import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../services/user_service.dart';
import '../../services/favorites_service.dart';
import '../../services/playback_manager.dart';
import '../widgets/track_tile.dart';
import '../../data/models/track.dart';
import '../../services/play_history_service.dart';
import '../../services/taste_analyzer.dart';

void showProfileModal(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _ProfileModal(),
  );
}

class _ProfileModal extends ConsumerStatefulWidget {
  const _ProfileModal();

  @override
  ConsumerState<_ProfileModal> createState() => _ProfileModalState();
}

class _ProfileModalState extends ConsumerState<_ProfileModal> {
  int _tabIndex = 0; // 0 = Favoritas, 1 = Frecuentes

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    final favs = ref.watch(favoritesProvider);
    // Para las frecuentes reutilizaremos la lógica del Home, podríamos pasarla, pero lo simplificaremos.

    final avatarColor =
        Color(int.parse(user.avatarColorHex.replaceFirst('#', '0xFF')));

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: AppTheme.background.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(
            top: BorderSide(color: AppTheme.primary.withOpacity(0.3), width: 1),
          ),
        ),
        child: Column(
          children: [
            // Grabber
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header: Avatar e Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: avatarColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: avatarColor.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'S',
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, ${user.name}',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Oyente Apasionado',
                          style: GoogleFonts.inter(
                            color: AppTheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${favs.length} Favoritas  •  ${user.preferredGenres.length} Géneros',
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      title: 'Favoritas',
                      icon: Icons.favorite_rounded,
                      isSelected: _tabIndex == 0,
                      onTap: () => setState(() => _tabIndex = 0),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TabButton(
                      title: 'Frecuentes',
                      icon: Icons.history_rounded,
                      isSelected: _tabIndex == 1,
                      onTap: () => setState(() => _tabIndex = 1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Contenido de Tabs
            Expanded(
              child: _tabIndex == 0
                  ? _buildFavoritesList(favs)
                  : FutureBuilder<List<Track>>(
                      future: TasteAnalyzer(PlayHistoryService())
                          .getMostPlayedTracks(limit: 50),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: AppTheme.primary));
                        }
                        final tracks = snapshot.data ?? [];
                        if (tracks.isEmpty) {
                          return _buildPlaceholder(
                              'Aún no hay suficientes datos\npara calcular tus más escuchadas.');
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: tracks.length,
                          itemBuilder: (context, i) {
                            return TrackTile(
                              track: tracks[i],
                              onTap: () {
                                ref
                                    .read(playbackManagerProvider)
                                    .setQueueAndPlay(tracks, i);
                                Navigator.pop(context);
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(List<Track> favs) {
    if (favs.isEmpty) {
      return _buildPlaceholder(
          'Aún no tienes favoritas.\nToca el corazón al escuchar.');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: favs.length,
      itemBuilder: (context, i) {
        final track = favs[i];
        return TrackTile(
          track: track,
          onTap: () {
            ref.read(playbackManagerProvider).setQueueAndPlay(favs, i);
            Navigator.pop(context); // Cerrar bottom sheet al dar play
          },
        );
      },
    );
  }

  Widget _buildPlaceholder(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_music_rounded,
              size: 60, color: AppTheme.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style:
                GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withOpacity(0.15)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
