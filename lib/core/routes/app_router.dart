import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../ui/screens/splash_screen.dart';
import '../../ui/screens/onboarding_screen.dart'; // Nuevo import
import '../../ui/screens/home_screen.dart';
import '../../ui/screens/library_screen.dart';
import '../../ui/screens/playlist_detail_screen.dart'; // Nuevo import
import '../../ui/screens/main_shell_screen.dart';
import '../../ui/screens/search_screen.dart';
import '../../ui/screens/settings_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/playlist/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return PlaylistDetailScreen(playlistId: id);
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShellScreen(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/library',
              builder: (context, state) => const LibraryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
