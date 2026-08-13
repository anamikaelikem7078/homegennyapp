import 'package:hive/hive.dart';

part 'video_certification_entity.g.dart';

@HiveType(typeId: 7)
class VideoCertificationEntity {
  VideoCertificationEntity({
    required this.id,
    required this.staffId,
    required this.filePath,
    required this.status,
    required this.uploadedAt,
    this.reviewReason,
    this.reviewedAt,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String staffId;

  @HiveField(2)
  final String filePath;

  @HiveField(3)
  final String status;

  @HiveField(4)
  final String? reviewReason;

  @HiveField(5)
  final DateTime uploadedAt;

  @HiveField(6)
  final DateTime? reviewedAt;
}
