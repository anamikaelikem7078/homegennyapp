import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/domain/models/staff_entity.dart';
import '../../../../common/presentation/providers/auth_provider.dart';
import '../../../../core/data/mutation_queue_service.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/storage/hive_service.dart';
import '../../data/repositories/rm_repository.dart';

final mutationQueueServiceProvider = Provider<MutationQueueService>((ref) {
  return MutationQueueService(ref.watch(hiveServiceProvider));
});

final rmRepositoryProvider = Provider<RmRepository>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  final mutationQueue = ref.watch(mutationQueueServiceProvider);
  return RmRepository(hiveService: hiveService, mutationQueue: mutationQueue);
});

// Dashboard Stats Provider
final rmDashboardStatsProvider = Provider<Map<String, int>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.user == null) return {};

  final repository = ref.watch(rmRepositoryProvider);
  
  // We can watch the hive box for changes to rebuild this provider.
  // Assuming hiveService.staffBox provides a stream of events.
  // For the APK prototype we will explicitly invalidate providers when mutations occur, 
  // or use ValueListenableBuilder at the widget level, but Riverpod is better.
  
  return repository.getDashboardStats(authState.user!.id);
});

// Staff Pipeline Provider
final rmPipelineProvider = Provider<Map<String, List<StaffEntity>>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.user == null) return {};

  final repository = ref.watch(rmRepositoryProvider);
  final allStaff = repository.getRmStaff(authState.user!.id);
  
  final Map<String, List<StaffEntity>> categorized = {
    'REGISTRATION': [],
    'VERIFICATION': [],
    'TRAINING': [],
    'VIDEO_CERTIFICATION': [],
    'AGREEMENT': [],
    'DEPLOYMENT': [],
    'TRIAL': [],
    'ACTIVE_PLACEMENT': [],
  };

  for (var staff in allStaff) {
    if (categorized.containsKey(staff.pipelineStage)) {
      categorized[staff.pipelineStage]!.add(staff);
    } else {
      categorized['REGISTRATION']!.add(staff); // fallback
    }
  }

  return categorized;
});

// Staff Detail Provider
final rmStaffDetailProvider = Provider.family<StaffEntity?, String>((ref, staffId) {
  final repository = ref.watch(rmRepositoryProvider);
  return repository.getStaffById(staffId);
});
