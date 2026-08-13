// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'replacement_request_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReplacementRequestEntityAdapter
    extends TypeAdapter<ReplacementRequestEntity> {
  @override
  final int typeId = 13;

  @override
  ReplacementRequestEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReplacementRequestEntity(
      id: fields[0] as String,
      clientId: fields[1] as String,
      staffId: fields[2] as String,
      reason: fields[3] as String,
      description: fields[4] as String,
      status: fields[5] as String,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ReplacementRequestEntity obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.clientId)
      ..writeByte(2)
      ..write(obj.staffId)
      ..writeByte(3)
      ..write(obj.reason)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReplacementRequestEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
