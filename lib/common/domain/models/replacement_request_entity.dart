import 'package:hive/hive.dart';

part 'replacement_request_entity.g.dart';

@HiveType(typeId: 13)
class ReplacementRequestEntity {
  ReplacementRequestEntity({
    required this.id,
    required this.clientId,
    required this.staffId,
    required this.reason,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String clientId;

  @HiveField(2)
  final String staffId;

  @HiveField(3)
  final String reason;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final String status;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;
}
