// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_mutation_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingMutationEntityAdapter extends TypeAdapter<PendingMutationEntity> {
  @override
  final int typeId = 15;

  @override
  PendingMutationEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingMutationEntity(
      id: fields[0] as String,
      entityType: fields[1] as String,
      entityId: fields[2] as String,
      action: fields[3] as String,
      payload: fields[4] as String,
      status: fields[5] as String,
      createdAt: fields[7] as DateTime,
      retryCount: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PendingMutationEntity obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.entityType)
      ..writeByte(2)
      ..write(obj.entityId)
      ..writeByte(3)
      ..write(obj.action)
      ..writeByte(4)
      ..write(obj.payload)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.retryCount)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingMutationEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
