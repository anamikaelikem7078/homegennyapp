import 'package:hive/hive.dart';

part 'notification_entity.g.dart';

@HiveType(typeId: 14)
class NotificationEntity {
  NotificationEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String message;

  @HiveField(4)
  final String type;

  @HiveField(5)
  final bool isRead;

  @HiveField(6)
  final DateTime createdAt;
}
