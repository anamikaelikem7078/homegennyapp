// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rm_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RMEntityAdapter extends TypeAdapter<RMEntity> {
  @override
  final int typeId = 3;

  @override
  RMEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RMEntity(
      id: fields[0] as String,
      rmCode: fields[1] as String,
      name: fields[2] as String,
      phone: fields[3] as String,
      status: fields[6] as String,
      email: fields[4] as String?,
      branch: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RMEntity obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.rmCode)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.branch)
      ..writeByte(6)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RMEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
