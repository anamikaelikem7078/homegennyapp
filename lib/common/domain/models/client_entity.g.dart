// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClientEntityAdapter extends TypeAdapter<ClientEntity> {
  @override
  final int typeId = 2;

  @override
  ClientEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClientEntity(
      id: fields[0] as String,
      clientCode: fields[1] as String,
      name: fields[2] as String,
      phone: fields[3] as String,
      status: fields[7] as String,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      email: fields[4] as String?,
      address: fields[5] as String?,
      assignedStaffIds: (fields[6] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ClientEntity obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.clientCode)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.address)
      ..writeByte(6)
      ..write(obj.assignedStaffIds)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
