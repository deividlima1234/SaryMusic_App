import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../data/models/track.dart';
import '../data/database/isar_service.dart';

final downloadServiceProvider = Provider<DownloadService>((ref) {
  final isarService = ref.read(isarServiceProvider);
  return DownloadService(isarService);
});

class DownloadService {
  final Dio _dio = Dio();
  final IsarService _isarService;

  DownloadService(this._isarService);

  Future<void> downloadTrack(
      Track track, String url, Function(double) onProgress) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/${track.youtubeId}.m4a';

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      // Guardar en la base local marcando como descargado
      track.localFilePath = savePath;
      await _isarService.saveTrack(track);
    } catch (e) {
      print('Error downloading track: $e');
      rethrow;
    }
  }
}
