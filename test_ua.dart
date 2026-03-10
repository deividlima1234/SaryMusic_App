import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;

void main() async {
  final yt = YoutubeExplode();
  final manifest =
      await yt.videos.streamsClient.getManifest('jNQXAC9IVRw'); // Me at the zoo
  final audioStreams =
      manifest.audioOnly.where((stream) => stream.container.name == 'mp4');
  final url = audioStreams.withHighestBitrate().url.toString();
  print('URL: $url');

  // Test curl to the url with ExoPlayer user agent
  final req = await http
      .get(Uri.parse(url), headers: {'User-Agent': 'ExoPlayerLib/2.18.7'});
  print('ExoPlayer UA Response: ${req.statusCode}');

  final req2 = await http.get(Uri.parse(url));
  print('Default Dart UA Response: ${req2.statusCode}');

  yt.close();
}
