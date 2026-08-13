import 'package:hive/hive.dart';

part 'payment_entity.g.dart';

@HiveType(typeId: 11)
class PaymentEntity {
  PaymentEntity({
    required this.id,
    required this.invoiceId,
    required this.clientId,
    required this.amount,
    required this.method,
    required this.date,
    required this.status,
    this.transactionReference,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String invoiceId;

  @HiveField(2)
  final String clientId;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final String method;

  @HiveField(5)
  final String? transactionReference;

  @HiveField(6)
  final DateTime date;

  @HiveField(7)
  final String status;
}
