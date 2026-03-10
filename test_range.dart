import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final manifest =
      await yt.videos.streamsClient.getManifest('jNQXAC9IVRw'); // Me at the zoo
  final streamInfo = manifest.audioOnly
      .where((s) => s.container.name == 'mp4')
      .withHighestBitrate();

  print('Obteniendo URL: ${streamInfo.url}');

  final client = HttpClient();
  final request = await client.getUrl(streamInfo.url);

  request.headers.set('User-Agent',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36');
  request.headers.set('Accept', '*/*');
  request.headers.set('Range', 'bytes=0-');

  final response = await request.close();
  print('Respuesta Range 0-: ${response.statusCode}');

  // Drenar para la siguiente
  await response.drain();

  final request2 = await client.getUrl(streamInfo.url);
  request2.headers.set('User-Agent',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36');
  request2.headers.set('Accept', '*/*');
  request2.headers.set('Range', 'bytes=100000-200000');

  final response2 = await request2.close();
  print('Respuesta Range 100K-200K: ${response2.statusCode}');

  await response2.drain();
  yt.close();
}
