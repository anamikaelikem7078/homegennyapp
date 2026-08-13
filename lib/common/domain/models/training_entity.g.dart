// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrainingEntityAdapter extends TypeAdapter<TrainingEntity> {
  @override
  final int typeId = 6;

  @override
  TrainingEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrainingEntity(
      id: fields[0] as String,
      staffId: fields[1] as String,
      courseId: fields[2] as String,
      title: fields[3] as String,
      progress: fields[4] as double,
      status: fields[5] as String,
      score: fields[6] as double?,
      passed: fields[7] as bool?,
      completedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TrainingEntity obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.staffId)
      ..writeByte(2)
      ..write(obj.courseId)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.progress)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.score)
      ..writeByte(7)
      ..write(obj.passed)
      ..writeByte(8)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
