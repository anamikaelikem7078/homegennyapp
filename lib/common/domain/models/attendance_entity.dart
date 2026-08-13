import 'package:hive/hive.dart';

part 'attendance_entity.g.dart';

@HiveType(typeId: 4)
class AttendanceEntity {
  AttendanceEntity({
    required this.id,
    required this.staffId,
    required this.clientId,
    required this.date,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.checkInTime,
    this.checkOutTime,
    this.workedMinutes,
    this.latitude,
    this.longitude,
    this.locationAvailable = false,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String staffId;

  @HiveField(2)
  final String clientId;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final DateTime? checkInTime;

  @HiveField(5)
  final DateTime? checkOutTime;

  @HiveField(6)
  final int? workedMinutes;

  @HiveField(7)
  final String status;

  @HiveField(8)
  final double? latitude;

  @HiveField(9)
  final double? longitude;

  @HiveField(10)
  final bool locationAvailable;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime updatedAt;
}
