import 'package:hive_ce/hive_ce.dart';

part 'downloaded_lecture_model.g.dart';

/// Stored in the `downloaded_lectures` Hive box, keyed by lecture id.
/// This is the record that lets the app answer "do I already have this
/// lecture on disk?" without touching the network.
@HiveType(typeId: 0)
class DownloadedLecture extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String sheikhName;

  @HiveField(3)
  final String localFilePath;

  @HiveField(4)
  final int downloadedAtEpoch;

  @HiveField(5)
  final int fileSizeBytes;

  DownloadedLecture({
    required this.id,
    required this.title,
    required this.sheikhName,
    required this.localFilePath,
    required this.downloadedAtEpoch,
    required this.fileSizeBytes,
  });

  DateTime get downloadedAt => DateTime.fromMillisecondsSinceEpoch(downloadedAtEpoch);
}
