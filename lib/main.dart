import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/database/isar_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Just Audio Background para notificaciones
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  // Inicializar Isar Database
  await IsarService.initialize();

  runApp(
    ProviderScope(
      child: SaryMusicApp(),
    ),
  );
}

class SaryMusicApp extends StatelessWidget {
  const SaryMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SaryMusic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.cyberneticPro,
      routerConfig: appRouter,
    );
  }
}
