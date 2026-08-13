// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvoiceEntityAdapter extends TypeAdapter<InvoiceEntity> {
  @override
  final int typeId = 10;

  @override
  InvoiceEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvoiceEntity(
      id: fields[0] as String,
      clientId: fields[1] as String,
      invoiceNumber: fields[2] as String,
      billingPeriod: fields[3] as String,
      subtotal: fields[4] as double,
      platformFee: fields[5] as double,
      gst: fields[6] as double,
      total: fields[7] as double,
      dueDate: fields[8] as DateTime,
      status: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, InvoiceEntity obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.clientId)
      ..writeByte(2)
      ..write(obj.invoiceNumber)
      ..writeByte(3)
      ..write(obj.billingPeriod)
      ..writeByte(4)
      ..write(obj.subtotal)
      ..writeByte(5)
      ..write(obj.platformFee)
      ..writeByte(6)
      ..write(obj.gst)
      ..writeByte(7)
      ..write(obj.total)
      ..writeByte(8)
      ..write(obj.dueDate)
      ..writeByte(9)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
