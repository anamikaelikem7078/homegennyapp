import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/result.dart';
import '../../domain/models/rm_models.dart';

export '../../../../core/di/injection.dart' show rmRepositoryProvider;

/// Reads follow the Staff/Client module convention: `FutureProvider` +
/// `.fold()`, real API only (see `RmRepositoryImpl`). Mutations are called
/// directly from screens via `ref.read(rmRepositoryProvider).method(...)`,
/// which then `ref.invalidate(...)` the providers below to refresh —
/// matching `check_in_screen.dart`'s pattern in the Staff module. There is
/// intentionally no mutation-provider layer here.

final rmDashboardProvider = FutureProvider<RmDashboard>((ref) async {
  final result = await ref.watch(rmRepositoryProvider).getDashboard();
  return result.fold(onSuccess: (d) => d, onError: (f) => throw f);
});

/// Kanban params — `null`/empty fields mean "no filter".
class KanbanParams {
  const KanbanParams({this.search, this.series, this.limit});
  final String? search;
  final String? series;
  final int? limit;

  @override
  bool operator ==(Object other) =>
      other is KanbanParams && other.search == search && other.series == series && other.limit == limit;

  @override
  int get hashCode => Object.hash(search, series, limit);
}

final rmKanbanProvider = FutureProvider.family<KanbanResult, KanbanParams>((ref, params) async {
  final result = await ref
      .watch(rmRepositoryProvider)
      .getKanban(search: params.search, series: params.series, limit: params.limit);
  return result.fold(onSuccess: (d) => d, onError: (f) => throw f);
});

/// No `GET /rm/staff/:id` exists on the backend — staff detail is always
/// resolved by finding the row inside the latest unfiltered kanban fetch.
/// See the plan's "Architecture decisions #4".
final staffByIdProvider = FutureProvider.family<StaffRow?, String>((ref, staffId) async {
  final kanban = await ref.watch(rmKanbanProvider(const KanbanParams()).future);
  return kanban.findById(staffId);
});

final rmTrialsProvider = FutureProvider<List<TrialRow>>((ref) async {
  final result = await ref.watch(rmRepositoryProvider).getTrials();
  return result.fold(onSuccess: (d) => d, onError: (f) => throw f);
});

final rmDeferredProvider = FutureProvider<List<DeferredRow>>((ref) async {
  final result = await ref.watch(rmRepositoryProvider).getDeferred();
  return result.fold(onSuccess: (d) => d, onError: (f) => throw f);
});

final rmTerminalProvider = FutureProvider<List<StaffRow>>((ref) async {
  final result = await ref.watch(rmRepositoryProvider).getTerminal();
  return result.fold(onSuccess: (d) => d, onError: (f) => throw f);
});

final rmIncidentsProvider = FutureProvider.family<List<IncidentRow>, String?>((ref, status) async {
  final result = await ref.watch(rmRepositoryProvider).getIncidents(status: status);
  return result.fold(onSuccess: (d) => d, onError: (f) => throw f);
});

final rmShiftsProvider = FutureProvider.family<List<ShiftLogRow>, String?>((ref, status) async {
  final result = await ref.watch(rmRepositoryProvider).getShifts(status: status);
  return result.fold(onSuccess: (d) => d, onError: (f) => throw f);
});

final rmUpgradesProvider = FutureProvider<List<UpgradeRequestRow>>((ref) async {
  final result = await ref.watch(rmRepositoryProvider).getUpgrades();
  return result.fold(onSuccess: (d) => d, onError: (f) => throw f);
});

final rmLocationsProvider = FutureProvider<LocationsData>((ref) async {
  final result = await ref.watch(rmRepositoryProvider).getLocations();
  return result.fold(onSuccess: (d) => d, onError: (f) => throw f);
});

class AttendanceParams {
  const AttendanceParams({required this.branchId, required this.month, required this.year});
  final String branchId;
  final int month;
  final int year;

  @override
  bool operator ==(Object other) =>
      other is AttendanceParams && other.branchId == branchId && other.month == month && other.year == year;

  @override
  int get hashCode => Object.hash(branchId, month, year);
}

final rmAttendanceProvider = FutureProvider.family<AttendanceMonthResult, AttendanceParams>((ref, params) async {
  final result = await ref
      .watch(rmRepositoryProvider)
      .getAttendance(branchId: params.branchId, month: params.month, year: params.year);
  return result.fold(onSuccess: (d) => d, onError: (f) => throw f);
});

class StaffPeriodParams {
  const StaffPeriodParams({required this.staffId, required this.month, required this.year});
  final String staffId;
  final int month;
  final int year;

  @override
  bool operator ==(Object other) =>
      other is StaffPeriodParams && other.staffId == staffId && other.month == month && other.year == year;

  @override
  int get hashCode => Object.hash(staffId, month, year);
}

final rmInvoicePreviewProvider = FutureProvider.family<InvoicePreview, StaffPeriodParams>((ref, params) async {
  final result =
      await ref.watch(rmRepositoryProvider).getInvoicePreview(params.staffId, month: params.month, year: params.year);
  return result.fold(onSuccess: (d) => d, onError: (f) => throw f);
});

final financeCustomersProvider = FutureProvider.family<List<FinanceCustomer>, String?>((ref, search) async {
  final result = await ref.watch(rmRepositoryProvider).getFinanceCustomers(search: search);
  return result.fold(onSuccess: (d) => d, onError: (f) => throw f);
});

class PlacementListParams {
  const PlacementListParams({this.staffId, this.clientId});
  final String? staffId;
  final String? clientId;

  @override
  bool operator ==(Object other) =>
      other is PlacementListParams && other.staffId == staffId && other.clientId == clientId;

  @override
  int get hashCode => Object.hash(staffId, clientId);
}

final rmPlacementsProvider = FutureProvider.family<List<PlacementRow>, PlacementListParams>((ref, params) async {
  final result = await ref.watch(rmRepositoryProvider).listPlacements(staffId: params.staffId, clientId: params.clientId);
  return result.fold(onSuccess: (d) => d, onError: (f) => throw f);
});

/// A staff member's most recent placement, or null if they have none yet.
final staffPlacementProvider = FutureProvider.family<PlacementRow?, String>((ref, staffId) async {
  final list = await ref.watch(rmPlacementsProvider(PlacementListParams(staffId: staffId)).future);
  if (list.isEmpty) return null;
  return list.reduce((a, b) => (a.createdAt ?? '').compareTo(b.createdAt ?? '') >= 0 ? a : b);
});

final rmAssessmentsProvider = FutureProvider<List<Assessment>>((ref) async {
  final result = await ref.watch(rmRepositoryProvider).listAssessments();
  return result.fold(onSuccess: (d) => d, onError: (f) => throw f);
});

/// A staff member's assessments, most recent first.
final staffAssessmentsProvider = FutureProvider.family<List<Assessment>, String>((ref, staffId) async {
  final all = await ref.watch(rmAssessmentsProvider.future);
  final mine = all.where((a) => a.staffId == staffId).toList()
    ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
  return mine;
});

class AgreementListParams {
  const AgreementListParams({this.staffId, this.clientId});
  final String? staffId;
  final String? clientId;

  @override
  bool operator ==(Object other) =>
      other is AgreementListParams && other.staffId == staffId && other.clientId == clientId;

  @override
  int get hashCode => Object.hash(staffId, clientId);
}

/// The client selected for a staff member's S4 Agreements instruments —
/// session-local, chosen once via the client picker and carried across the
/// A1/A2/A3 screens for that staff.
final agreementClientProvider = StateProvider.family<FinanceCustomer?, String>((ref, staffId) => null);

final rmAgreementsProvider = FutureProvider.family<List<Agreement>, AgreementListParams>((ref, params) async {
  final result = await ref.watch(rmRepositoryProvider).listAgreements(staffId: params.staffId, clientId: params.clientId);
  return result.fold(onSuccess: (d) => d, onError: (f) => throw f);
});

final rmSowListProvider = FutureProvider.family<List<ScopeOfWork>, String>((ref, placementId) async {
  final result = await ref.watch(rmRepositoryProvider).listSow(placementId);
  return result.fold(onSuccess: (d) => d, onError: (f) => throw f);
});

final rmIndemnityListProvider = FutureProvider.family<List<ClientIndemnity>, String>((ref, placementId) async {
  final result = await ref.watch(rmRepositoryProvider).listIndemnity(placementId);
  return result.fold(onSuccess: (d) => d, onError: (f) => throw f);
});

final rmVideoCertPromptsProvider = FutureProvider.family<VideoCertPrompts, String>((ref, series) async {
  final result = await ref.watch(rmRepositoryProvider).getVideoCertPrompts(series);
  return result.fold(onSuccess: (d) => d, onError: (f) => throw f);
});

final rmVideoCertsProvider = FutureProvider.family<List<VideoCertItem>, String>((ref, staffId) async {
  final result = await ref.watch(rmRepositoryProvider).listVideoCerts(staffId);
  return result.fold(onSuccess: (d) => d, onError: (f) => throw f);
});

/// Session-local (not persisted) verification-track "attempted" flags —
/// see the plan's "Architecture decisions #6": there's a real
/// `GET /verification/:staffId` now, so this is used only as a fallback
/// when that call fails (e.g. pre-redeploy backend), not as the primary
/// source of truth.
final verificationSessionProvider =
    StateProvider.family<Set<String>, String>((ref, staffId) => <String>{});

/// Session-local carry-over of the Aadhaar number entered at S1 intake, so
/// the Aadhaar eKYC screen (S2) can pre-fill it. The backend never stores
/// or returns the raw Aadhaar number (`toStaffDto` only exposes a
/// `restricted_list` table keyed by a SHA hash, not the plaintext number —
/// see `staff.mapper.ts` / `schema.prisma`), so there is no server-side
/// value to fetch here; this only survives for the current app session.
final intakeAadhaarProvider = StateProvider.family<String?, String>((ref, staffId) => null);

final rmVerificationStatusProvider = FutureProvider.family<Map<String, String>, String>((ref, staffId) async {
  final result = await ref.watch(rmRepositoryProvider).getVerificationStatus(staffId);
  return result.fold(onSuccess: (d) => d, onError: (_) => const {});
});

/// The Aadhaar track's already-persisted result, if S2's Aadhaar eKYC was
/// previously cleared for this staff — `null` means "not verified yet",
/// distinct from a fetch error, so the screen can tell "show the entry
/// form" apart from "still loading".
final rmAadhaarVerificationResultProvider = FutureProvider.family<AadhaarResult?, String>((ref, staffId) async {
  final result = await ref.watch(rmRepositoryProvider).getAadhaarVerificationResult(staffId);
  return result.fold(onSuccess: (d) => d, onError: (_) => null);
});
