import 'package:isar/isar.dart';
import 'track.dart';

part 'playlist.g.dart';

@collection
class Playlist {
  Id id = Isar.autoIncrement;

  late String name;
  String? description;
  DateTime creationDate = DateTime.now();

  // Canciones contenidas
  final tracks = IsarLinks<Track>();
}
