// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentEntityAdapter extends TypeAdapter<PaymentEntity> {
  @override
  final int typeId = 11;

  @override
  PaymentEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaymentEntity(
      id: fields[0] as String,
      invoiceId: fields[1] as String,
      clientId: fields[2] as String,
      amount: fields[3] as double,
      method: fields[4] as String,
      date: fields[6] as DateTime,
      status: fields[7] as String,
      transactionReference: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PaymentEntity obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.invoiceId)
      ..writeByte(2)
      ..write(obj.clientId)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.method)
      ..writeByte(5)
      ..write(obj.transactionReference)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
