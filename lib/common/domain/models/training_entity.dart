import 'package:hive/hive.dart';

part 'training_entity.g.dart';

@HiveType(typeId: 6)
class TrainingEntity {
  TrainingEntity({
    required this.id,
    required this.staffId,
    required this.courseId,
    required this.title,
    required this.progress,
    required this.status,
    this.score,
    this.passed,
    this.completedAt,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String staffId;

  @HiveField(2)
  final String courseId;

  @HiveField(3)
  final String title;

  @HiveField(4)
  final double progress;

  @HiveField(5)
  final String status;

  @HiveField(6)
  final double? score;

  @HiveField(7)
  final bool? passed;

  @HiveField(8)
  final DateTime? completedAt;
}
