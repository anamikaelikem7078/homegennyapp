// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceEntityAdapter extends TypeAdapter<AttendanceEntity> {
  @override
  final int typeId = 4;

  @override
  AttendanceEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttendanceEntity(
      id: fields[0] as String,
      staffId: fields[1] as String,
      clientId: fields[2] as String,
      date: fields[3] as DateTime,
      status: fields[7] as String,
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime,
      checkInTime: fields[4] as DateTime?,
      checkOutTime: fields[5] as DateTime?,
      workedMinutes: fields[6] as int?,
      latitude: fields[8] as double?,
      longitude: fields[9] as double?,
      locationAvailable: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceEntity obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.staffId)
      ..writeByte(2)
      ..write(obj.clientId)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.checkInTime)
      ..writeByte(5)
      ..write(obj.checkOutTime)
      ..writeByte(6)
      ..write(obj.workedMinutes)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.latitude)
      ..writeByte(9)
      ..write(obj.longitude)
      ..writeByte(10)
      ..write(obj.locationAvailable)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
