import 'package:hive/hive.dart';

import '../../common/domain/models/agreement_entity.dart';
import '../../common/domain/models/attendance_entity.dart';
import '../../common/domain/models/client_entity.dart';
import '../../common/domain/models/complaint_entity.dart';
import '../../common/domain/models/document_entity.dart';
import '../../common/domain/models/invoice_entity.dart';
import '../../common/domain/models/notification_entity.dart';
import '../../common/domain/models/payment_entity.dart';
import '../../common/domain/models/pending_mutation_entity.dart';
import '../../common/domain/models/placement_entity.dart';
import '../../common/domain/models/replacement_request_entity.dart';
import '../../common/domain/models/rm_entity.dart';
import '../../common/domain/models/staff_entity.dart';
import '../../common/domain/models/training_entity.dart';
import '../../common/domain/models/video_certification_entity.dart';

void registerHiveAdapters() {
  Hive.registerAdapter(StaffEntityAdapter()); // 1
  Hive.registerAdapter(ClientEntityAdapter()); // 2
  Hive.registerAdapter(RMEntityAdapter()); // 3
  Hive.registerAdapter(AttendanceEntityAdapter()); // 4
  Hive.registerAdapter(DocumentEntityAdapter()); // 5
  Hive.registerAdapter(TrainingEntityAdapter()); // 6
  Hive.registerAdapter(VideoCertificationEntityAdapter()); // 7
  Hive.registerAdapter(AgreementEntityAdapter()); // 8
  Hive.registerAdapter(PlacementEntityAdapter()); // 9
  Hive.registerAdapter(InvoiceEntityAdapter()); // 10
  Hive.registerAdapter(PaymentEntityAdapter()); // 11
  Hive.registerAdapter(ComplaintEntityAdapter()); // 12
  Hive.registerAdapter(ReplacementRequestEntityAdapter()); // 13
  Hive.registerAdapter(NotificationEntityAdapter()); // 14
  Hive.registerAdapter(PendingMutationEntityAdapter()); // 15
}
