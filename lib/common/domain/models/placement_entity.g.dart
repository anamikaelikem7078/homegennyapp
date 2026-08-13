// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'placement_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlacementEntityAdapter extends TypeAdapter<PlacementEntity> {
  @override
  final int typeId = 9;

  @override
  PlacementEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlacementEntity(
      id: fields[0] as String,
      staffId: fields[1] as String,
      clientId: fields[2] as String,
      deploymentDate: fields[3] as DateTime,
      status: fields[5] as String,
      trialDate: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PlacementEntity obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.staffId)
      ..writeByte(2)
      ..write(obj.clientId)
      ..writeByte(3)
      ..write(obj.deploymentDate)
      ..writeByte(4)
      ..write(obj.trialDate)
      ..writeByte(5)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlacementEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
