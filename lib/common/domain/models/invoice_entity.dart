import 'package:hive/hive.dart';

part 'invoice_entity.g.dart';

@HiveType(typeId: 10)
class InvoiceEntity {
  InvoiceEntity({
    required this.id,
    required this.clientId,
    required this.invoiceNumber,
    required this.billingPeriod,
    required this.subtotal,
    required this.platformFee,
    required this.gst,
    required this.total,
    required this.dueDate,
    required this.status,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String clientId;

  @HiveField(2)
  final String invoiceNumber;

  @HiveField(3)
  final String billingPeriod;

  @HiveField(4)
  final double subtotal;

  @HiveField(5)
  final double platformFee;

  @HiveField(6)
  final double gst;

  @HiveField(7)
  final double total;

  @HiveField(8)
  final DateTime dueDate;

  @HiveField(9)
  final String status;
}
