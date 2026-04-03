import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/theme/app_theme.dart';
import '../../services/audio_player_service.dart';

class EqualizerScreen extends ConsumerStatefulWidget {
  const EqualizerScreen({super.key});

  @override
  ConsumerState<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends ConsumerState<EqualizerScreen> {
  // Función para formatear las frecuencias de manera bonita
  String _formatFreq(double centerFreq) {
    if (centerFreq < 1000) {
      return '${centerFreq.round()}Hz';
    } else {
      return '${(centerFreq / 1000).toStringAsFixed(1)}kHz';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Ecualizador', style: GoogleFonts.orbitron()),
        ),
        body: Center(
          child: Text(
            'El ecualizador avanzado solo está disponible en Android.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    final audioService = ref.watch(audioPlayerServiceProvider);
    final equalizer = audioService.equalizer;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'ECUALIZADOR',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primary.withOpacity(0.1),
              AppTheme.background,
            ],
          ),
        ),
        child: FutureBuilder<AndroidEqualizerParameters>(
          future: equalizer.parameters,
          builder: (context, snapshot) {
            final params = snapshot.data;

            if (params == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }

            return StreamBuilder<bool>(
              stream: equalizer.enabledStream,
              initialData: false,
              builder: (context, enabledSnapshot) {
                final isEnabled = enabledSnapshot.data ?? false;

                return Column(
                  children: [
                    const SizedBox(height: 20),
                    // Switch de Activación
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isEnabled 
                            ? AppTheme.primary.withOpacity(0.5) 
                            : Colors.white10,
                        ),
                        boxShadow: isEnabled
                          ? [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.2),
                                blurRadius: 15,
                                spreadRadius: -5,
                              )
                            ]
                          : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.graphic_eq_rounded,
                                color: isEnabled ? AppTheme.primary : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isEnabled ? 'Activado' : 'Desactivado',
                                style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: isEnabled,
                            activeColor: AppTheme.primary,
                            inactiveTrackColor: Colors.white12,
                            onChanged: (value) async {
                              await audioService.saveEqualizerEnabled(value);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Sliders del Ecualizador
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (int i = 0; i < params.bands.length; i++)
                              _buildEqBand(
                                params.bands[i],
                                isEnabled,
                                params.minDecibels,
                                params.maxDecibels,
                                audioService,
                                i,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Presets Píldoras (Opcional decorativa)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Personalizado',
                            style: GoogleFonts.orbitron(
                              color: AppTheme.primary,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEqBand(
    AndroidEqualizerBand band,
    bool isEnabled,
    double minDb,
    double maxDb,
    AudioPlayerService audioService,
    int index,
  ) {
    return StreamBuilder<double>(
      stream: band.gainStream,
      initialData: 0.0,
      builder: (context, snapshot) {
        double currentGain = snapshot.data ?? 0.0;
        // Sanitizar el slider range just in case
        if (currentGain < minDb) currentGain = minDb;
        if (currentGain > maxDb) currentGain = maxDb;

        return Column(
          children: [
            // Valor actual en dB (Arriba)
            Text(
              '${currentGain > 0 ? '+' : ''}${currentGain.toStringAsFixed(1)}',
              style: GoogleFonts.inter(
                color: isEnabled ? Colors.white : AppTheme.textSecondary.withOpacity(0.5),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Slider Vertical
            Expanded(
              child: RotatedBox(
                quarterTurns: 3,
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    activeTrackColor: isEnabled ? AppTheme.primary : Colors.white24,
                    inactiveTrackColor: Colors.white10,
                    thumbColor: isEnabled ? Colors.white : Colors.white54,
                    overlayColor: AppTheme.primary.withOpacity(0.2),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: currentGain,
                    min: minDb,
                    max: maxDb,
                    onChanged: isEnabled
                      ? (value) {
                          band.setGain(value);
                        }
                      : null,
                    onChangeEnd: isEnabled
                      ? (value) {
                          audioService.saveEqualizerGain(index, value);
                        }
                      : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Frecuencia de la banda (Abajo)
            Text(
              _formatFreq(band.centerFrequency),
              style: GoogleFonts.inter(
                color: isEnabled ? AppTheme.primary : AppTheme.textSecondary.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}
