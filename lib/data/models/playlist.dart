import 'package:isar/isar.dart';
import 'track.dart';

part 'playlist.g.dart';

@collection
class Playlist {
  Id id = Isar.autoIncrement;

  late String name;
  String? description;
  DateTime creationDate = DateTime.now();
  late bool
      isLocal; // Distingue entre playlist online o local (archivos descargados)

  // Canciones contenidas
  final tracks = IsarLinks<Track>();
}
