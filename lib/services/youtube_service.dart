import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../data/models/track.dart';

final youtubeServiceProvider = Provider<YoutubeService>((ref) {
  return YoutubeService();
});

class YoutubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  Future<List<Track>> searchTracks(String query) async {
    final searchResults = await _yt.search(query);
    return searchResults.map((video) {
      return Track()
        ..youtubeId = video.id.value
        ..title = video.title
        ..artist = video.author
        ..durationSeconds = video.duration?.inSeconds ?? 0
        ..thumbnailUrl = video.thumbnails.highResUrl;
    }).toList();
  }

  Future<AudioOnlyStreamInfo?> getStreamInfo(String videoId) async {
    // Probar cliente mweb para generar URLs accesibles desde Dart HTTP client
    // (evita c=ANDROID que bloquea la descarga, e iOS que falla en videos con streams de video restringidos)
    StreamManifest? manifest;
    final clientsToTry = [
      [YoutubeApiClient.mweb],
      [YoutubeApiClient.tv],
      [YoutubeApiClient.androidVr],
    ];

    for (final clients in clientsToTry) {
      try {
        manifest = await _yt.videos.streamsClient.getManifest(
          videoId,
          ytClients: clients,
        );
        print('[YoutubeService] Manifest obtenido con cliente: $clients');
        break;
      } catch (e) {
        print('[YoutubeService] Cliente $clients falló: $e');
        continue;
      }
    }

    if (manifest == null) return null;

    final audioStreams =
        manifest.audioOnly.where((s) => s.container.name == 'mp4');
    if (audioStreams.isEmpty) {
      return manifest.audioOnly.isNotEmpty
          ? manifest.audioOnly.withHighestBitrate()
          : null;
    }
    return audioStreams.withHighestBitrate();
  }

  /// Retorna la URL del stream de audio para reproducción instantánea.
  Future<String?> getAudioUrl(String videoId) async {
    final streamInfo = await getStreamInfo(videoId);
    return streamInfo?.url.toString();
  }

  /// Descarga el audio permanentemente (para escuchar sin internet).
  /// [onProgress] recibe un valor de 0.0 a 1.0 durante la descarga.
  /// Retorna la ruta local del archivo .m4a guardado.
  Future<String> downloadAudioPermanent(
    AudioOnlyStreamInfo streamInfo,
    String videoId, {
    void Function(double progress)? onProgress,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final musicDir = Directory('${docsDir.path}/sarymusic_downloads');
    if (!await musicDir.exists()) await musicDir.create(recursive: true);

    final file = File('${musicDir.path}/$videoId.m4a');

    final totalBytes = streamInfo.size.totalBytes;
    final stream = _yt.videos.streamsClient.get(streamInfo);
    final fileStream = file.openWrite();
    int bytesReceived = 0;

    await for (final chunk in stream) {
      fileStream.add(chunk);
      bytesReceived += chunk.length;
      if (totalBytes > 0) {
        onProgress?.call(bytesReceived / totalBytes);
      }
    }

    await fileStream.flush();
    await fileStream.close();
    return file.path;
  }
}
