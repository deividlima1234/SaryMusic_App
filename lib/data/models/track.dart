import 'package:isar/isar.dart';
import 'playlist.dart';

part 'track.g.dart';

@collection
class Track {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String youtubeId;

  late String title;
  late String artist;
  late String thumbnailUrl;
  late int durationSeconds;

  // Si es null, la canción se reproduce por streaming.
  // Si tiene datos, significa que fue descargada y se lee desde disco.
  String? localFilePath;

  // Relaciones
  @Backlink(to: 'tracks')
  final playlists = IsarLinks<Playlist>();
}
