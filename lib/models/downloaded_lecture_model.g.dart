// GENERATED CODE - written by hand to match what `dart run build_runner build`
// would normally produce, so the project compiles before you've run codegen.
// If you add/remove fields on DownloadedLecture, delete this file and run:
//   dart run build_runner build --delete-conflicting-outputs
// to regenerate it properly.

part of 'downloaded_lecture_model.dart';

class DownloadedLectureAdapter extends TypeAdapter<DownloadedLecture> {
  @override
  final int typeId = 0;

  @override
  DownloadedLecture read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadedLecture(
      id: fields[0] as String,
      title: fields[1] as String,
      sheikhName: fields[2] as String,
      localFilePath: fields[3] as String,
      downloadedAtEpoch: fields[4] as int,
      fileSizeBytes: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DownloadedLecture obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.sheikhName)
      ..writeByte(3)
      ..write(obj.localFilePath)
      ..writeByte(4)
      ..write(obj.downloadedAtEpoch)
      ..writeByte(5)
      ..write(obj.fileSizeBytes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadedLectureAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
