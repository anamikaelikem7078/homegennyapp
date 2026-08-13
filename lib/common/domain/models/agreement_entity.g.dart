// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agreement_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AgreementEntityAdapter extends TypeAdapter<AgreementEntity> {
  @override
  final int typeId = 8;

  @override
  AgreementEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AgreementEntity(
      id: fields[0] as String,
      staffId: fields[1] as String,
      status: fields[2] as String,
      signaturePath: fields[3] as String?,
      signedAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AgreementEntity obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.staffId)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.signaturePath)
      ..writeByte(4)
      ..write(obj.signedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgreementEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
