// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_certification_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VideoCertificationEntityAdapter
    extends TypeAdapter<VideoCertificationEntity> {
  @override
  final int typeId = 7;

  @override
  VideoCertificationEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VideoCertificationEntity(
      id: fields[0] as String,
      staffId: fields[1] as String,
      filePath: fields[2] as String,
      status: fields[3] as String,
      uploadedAt: fields[5] as DateTime,
      reviewReason: fields[4] as String?,
      reviewedAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, VideoCertificationEntity obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.staffId)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.reviewReason)
      ..writeByte(5)
      ..write(obj.uploadedAt)
      ..writeByte(6)
      ..write(obj.reviewedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoCertificationEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
