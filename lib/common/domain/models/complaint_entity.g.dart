// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complaint_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ComplaintEntityAdapter extends TypeAdapter<ComplaintEntity> {
  @override
  final int typeId = 12;

  @override
  ComplaintEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ComplaintEntity(
      id: fields[0] as String,
      clientId: fields[1] as String,
      staffId: fields[2] as String,
      subject: fields[3] as String,
      description: fields[4] as String,
      status: fields[6] as String,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      attachments: (fields[5] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ComplaintEntity obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.clientId)
      ..writeByte(2)
      ..write(obj.staffId)
      ..writeByte(3)
      ..write(obj.subject)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.attachments)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComplaintEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
