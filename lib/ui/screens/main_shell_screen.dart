import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/mini_player.dart';

class MainShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  void _onItemTapped(int index, BuildContext context) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SaryMusic'),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: AppTheme.surface,
              child: Icon(Icons.person, color: AppTheme.textSecondary),
            ),
            onPressed: () {
              // TODO: Abrir perfil
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          navigationShell,

          // Mini-Player Flotante global anclado arriba de la NavBar
          Positioned(
            left: 0,
            right: 0,
            bottom:
                90, // Suficiente espacio para no tapar el BottomNavigationBar customizado
            child: const MiniPlayer(),
          ),
        ],
      ),
      extendBody: true, // Permite que el contenido vaya bajo el bottom app bar
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface.withOpacity(0.85),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) => _onItemTapped(index, context),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search_outlined),
                activeIcon: Icon(Icons.search),
                label: 'Buscar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music_outlined),
                activeIcon: Icon(Icons.library_music),
                label: 'Biblioteca',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Más',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
