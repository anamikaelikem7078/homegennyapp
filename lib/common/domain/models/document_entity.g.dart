// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DocumentEntityAdapter extends TypeAdapter<DocumentEntity> {
  @override
  final int typeId = 5;

  @override
  DocumentEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DocumentEntity(
      id: fields[0] as String,
      staffId: fields[1] as String,
      type: fields[2] as String,
      name: fields[3] as String,
      filePath: fields[4] as String,
      status: fields[5] as String,
      uploadedAt: fields[7] as DateTime,
      rejectionReason: fields[6] as String?,
      reviewedAt: fields[8] as DateTime?,
      reviewerId: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DocumentEntity obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.staffId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.filePath)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.rejectionReason)
      ..writeByte(7)
      ..write(obj.uploadedAt)
      ..writeByte(8)
      ..write(obj.reviewedAt)
      ..writeByte(9)
      ..write(obj.reviewerId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
