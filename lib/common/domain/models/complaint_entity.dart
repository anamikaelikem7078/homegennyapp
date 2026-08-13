import 'package:hive/hive.dart';

part 'complaint_entity.g.dart';

@HiveType(typeId: 12)
class ComplaintEntity {
  ComplaintEntity({
    required this.id,
    required this.clientId,
    required this.staffId,
    required this.subject,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.attachments = const [],
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String clientId;

  @HiveField(2)
  final String staffId;

  @HiveField(3)
  final String subject;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final List<String> attachments;

  @HiveField(6)
  final String status;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime updatedAt;
}
