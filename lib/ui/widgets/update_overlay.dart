import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_theme.dart';
import '../../services/update_service.dart';
import '../../services/notification_service.dart';

class UpdateOverlay extends StatefulWidget {
  final AppUpdateInfo updateInfo;

  const UpdateOverlay({super.key, required this.updateInfo});

  @override
  State<UpdateOverlay> createState() => _UpdateOverlayState();
}

class _UpdateOverlayState extends State<UpdateOverlay> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusMessage = '';

  Future<void> _startDownload() async {
    if (_isDownloading) return;

    // Verificar permisos
    if (Platform.isAndroid) {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
      // Dependiendo de la versión de Android, se necesita permiso de almacenamiento,
      // pero en Android modernos las carpetas de caché/app_docs no lo requieren.
      // Así que procedemos directamentamente al directorio temporal.
    }

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _statusMessage = 'Iniciando descarga...';
    });

    final dio = Dio();
    final url = widget.updateInfo.downloadUrl;
    
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/sarymusic_update_${widget.updateInfo.latestVersion}.apk';

      await NotificationService().showDownloadProgress(
        0, 
        100, 
        'SaryMusic ${widget.updateInfo.latestVersion}', 
        'Iniciando descarga...'
      );

      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final double progressPercentage = received / total;
            final int progressInt = (progressPercentage * 100).toInt();
            
            // Actualizar UI y Notificación con frecuencia razonable para evitar saturación
            if ((progressPercentage * 100).toInt() % 2 == 0) {
              setState(() {
                _progress = progressPercentage;
                _statusMessage = 'Descargando... $progressInt%';
              });

              NotificationService().showDownloadProgress(
                progressInt, 
                100, 
                'Descargando Actualización', 
                '$progressInt% completado'
              );
            }
          }
        },
      );

      setState(() {
        _statusMessage = 'Descarga completada. Iniciando instalación...';
      });

      await NotificationService().showDownloadCompleted(
        'Actualización descargada', 
        'La actualización está lista para instalar.',
      );

      // Lanzar el APK para instalar
      final result = await OpenFilex.open(filePath);
      
      if (result.type != ResultType.done) {
        setState(() {
          _statusMessage = 'Error al abrir el instalador: ${result.message}';
          _isDownloading = false;
        });
      }

    } catch (e) {
      setState(() {
        _statusMessage = 'Error al descargar: $e';
        _isDownloading = false;
      });
      NotificationService().showDownloadError(
        'Error en la descarga', 
        'No se pudo descargar la actualización.'
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(Icons.system_update_rounded,
              color: AppTheme.primary, size: 48),
          const SizedBox(height: 16),
          Text(
            '¡NUEVA VERSIÓN DISPONIBLE!',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'La versión ${widget.updateInfo.latestVersion} ya está lista para descargar con mejoras y correcciones.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          
          if (_isDownloading) ...[
            Text(
              _statusMessage,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 12,
                backgroundColor: Colors.white12,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _startDownload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: AppTheme.primary.withOpacity(0.5),
                ),
                child: Text(
                  'DESCARGAR ACTUALIZACIÓN',
                  style: GoogleFonts.orbitron(
                      fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'MÁS TARDE',
                style: GoogleFonts.orbitron(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

void showUpdateIfNeeded(BuildContext context, AppUpdateInfo updateInfo) {
  if (updateInfo.hasUpdate) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false, // Evita cerrar el modal mientras se descarga
      enableDrag: false,
      builder: (context) => PopScope(
        canPop: false, // Evita salir hacia atrás
        child: UpdateOverlay(updateInfo: updateInfo),
      ),
    );
  }
}
