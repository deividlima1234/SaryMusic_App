import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/playlist.dart';
import '../models/track.dart';

final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService();
});

class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = openDB();
  }

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    if (Isar.instanceNames.isEmpty) {
      await Isar.open(
        [TrackSchema, PlaylistSchema],
        directory: dir.path,
        inspector: true,
      );
    }
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [TrackSchema, PlaylistSchema],
        directory: dir.path,
        inspector: true,
      );
    }
    return Future.value(Isar.getInstance());
  }

  Future<void> saveTrack(Track track) async {
    final isar = await db;
    isar.writeTxnSync<int>(() => isar.tracks.putSync(track));
  }

  Future<List<Track>> getAllTracks() async {
    final isar = await db;
    return await isar.tracks.where().findAll();
  }

  Future<Track?> getTrackByYoutubeId(String youtubeId) async {
    final isar = await db;
    return await isar.tracks.where().youtubeIdEqualTo(youtubeId).findFirst();
  }

  Future<List<Track>> getDownloadedTracks() async {
    final isar = await db;
    return await isar.tracks.filter().localFilePathIsNotNull().findAll();
  }

  Future<void> deleteTrack(Track track) async {
    final isar = await db;
    await isar.writeTxn(() => isar.tracks.delete(track.id));
  }
}
