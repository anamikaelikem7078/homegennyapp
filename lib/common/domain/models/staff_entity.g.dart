// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StaffEntityAdapter extends TypeAdapter<StaffEntity> {
  @override
  final int typeId = 1;

  @override
  StaffEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StaffEntity(
      id: fields[0] as String,
      staffCode: fields[1] as String,
      name: fields[2] as String,
      phone: fields[3] as String,
      status: fields[7] as String,
      pipelineStage: fields[8] as String,
      createdAt: fields[17] as DateTime,
      updatedAt: fields[18] as DateTime,
      email: fields[4] as String?,
      profileImage: fields[5] as String?,
      address: fields[6] as String?,
      rmId: fields[9] as String?,
      clientId: fields[10] as String?,
      verification: fields[11] as String?,
      training: fields[12] as String?,
      videoCertification: fields[13] as String?,
      agreement: fields[14] as String?,
      deployment: fields[15] as String?,
      trial: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, StaffEntity obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.staffCode)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.profileImage)
      ..writeByte(6)
      ..write(obj.address)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.pipelineStage)
      ..writeByte(9)
      ..write(obj.rmId)
      ..writeByte(10)
      ..write(obj.clientId)
      ..writeByte(11)
      ..write(obj.verification)
      ..writeByte(12)
      ..write(obj.training)
      ..writeByte(13)
      ..write(obj.videoCertification)
      ..writeByte(14)
      ..write(obj.agreement)
      ..writeByte(15)
      ..write(obj.deployment)
      ..writeByte(16)
      ..write(obj.trial)
      ..writeByte(17)
      ..write(obj.createdAt)
      ..writeByte(18)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
