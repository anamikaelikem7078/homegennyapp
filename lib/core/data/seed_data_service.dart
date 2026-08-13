import 'dart:convert';
import 'package:flutter/services.dart';

import '../../common/domain/models/client_entity.dart';
import '../../common/domain/models/rm_entity.dart';
import '../../common/domain/models/staff_entity.dart';
import '../storage/hive_service.dart';
import '../utils/logger.dart';

class SeedDataService {
  SeedDataService(this._hiveService);

  final HiveService _hiveService;

  Future<void> seedIfEmpty() async {
    try {
      if (_hiveService.staffBox.isEmpty &&
          _hiveService.clientBox.isEmpty &&
          _hiveService.rmBox.isEmpty) {
        
        AppLogger.i('Hive is empty. Seeding demo data...');
        
        // 1. Create a dummy RM
        final demoRm = RMEntity(
          id: 'rm-demo-1',
          rmCode: 'RM-001',
          name: 'Demo RM',
          phone: '9800000001',
          status: 'ACTIVE',
        );
        await _hiveService.rmBox.put(demoRm.id, demoRm);

        // 2. Create a dummy Staff
        final demoStaff = StaffEntity(
          id: 'staff-demo-1',
          staffCode: 'ST-001',
          name: 'Demo Staff',
          phone: '9800000002',
          status: 'AVAILABLE',
          pipelineStage: 'DEPLOYED',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          rmId: demoRm.id,
          clientId: 'client-demo-1',
        );
        await _hiveService.staffBox.put(demoStaff.id, demoStaff);

        // 3. Create a dummy Client
        final demoClient = ClientEntity(
          id: 'client-demo-1',
          clientCode: 'CL-001',
          name: 'Demo Client',
          phone: '9800000004',
          status: 'ACTIVE',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          assignedStaffIds: [demoStaff.id],
        );
        await _hiveService.clientBox.put(demoClient.id, demoClient);

        AppLogger.i('Demo data seeded successfully.');
      }
    } catch (e, st) {
      AppLogger.e('Failed to seed data', e, st);
    }
  }

  Future<void> resetDemoData() async {
    AppLogger.w('Resetting demo data...');
    await _hiveService.staffBox.clear();
    await _hiveService.clientBox.clear();
    await _hiveService.rmBox.clear();
    await _hiveService.attendanceBox.clear();
    await _hiveService.documentBox.clear();
    await _hiveService.trainingBox.clear();
    await _hiveService.videoCertificationBox.clear();
    await _hiveService.agreementBox.clear();
    await _hiveService.placementBox.clear();
    await _hiveService.invoiceBox.clear();
    await _hiveService.paymentBox.clear();
    await _hiveService.complaintBox.clear();
    await _hiveService.replacementRequestBox.clear();
    await _hiveService.notificationBox.clear();
    await _hiveService.pendingMutationBox.clear();

    await seedIfEmpty();
  }
}
