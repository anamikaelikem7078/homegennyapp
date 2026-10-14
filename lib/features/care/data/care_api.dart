import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../core/exceptions/exception_handler.dart';
import '../../../core/network/api_service.dart';
import '../../../core/utils/result.dart';
import '../domain/care_models.dart';
import '../domain/cook_models.dart';
import '../domain/client_update_models.dart';
import '../domain/instruction_models.dart';

/// Daily-care endpoints (`/care/placements/:pid/…`, `/staff/care/…`,
/// `/care-files`). The backend decides per call what the caller (client,
/// staff or RM) may see and do.
class CareApi extends BaseRemoteDataSource {
  CareApi(super.dio);

  static String _p(String pid) => '/care/placements/$pid';

  /// Runs [call], turning any error into a [Failure] whose message is the
  /// server's `message.message`.
  Future<Result<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Success(await call());
    } catch (e, st) {
      return Error(ExceptionHandler.handle(e, st));
    }
  }

  // ── Plan ──
  Future<Result<CarePlanView>> getPlan(String pid) =>
      _guard(() async => CarePlanView.fromJson(await getJson('${_p(pid)}/plan')));

  Future<Result<CarePlanView>> savePlan(String pid, CarePlan plan) =>
      _guard(() async => CarePlanView.fromJson(await putJson('${_p(pid)}/plan', data: plan.toJson())));

  // ── Day / history / report ──
  Future<Result<CareDay>> getDay(String pid, {String? date}) => _guard(() async => CareDay.fromJson(
        await getJson('${_p(pid)}/day', queryParameters: {'date': ?date}),
      ));

  Future<Result<CareHistory>> getHistory(String pid, {String? from, String? to}) =>
      _guard(() async => CareHistory.fromJson(
            await getJson('${_p(pid)}/history', queryParameters: {'from': ?from, 'to': ?to}),
          ));

  /// Monthly report PDF (`month` = YYYY-MM).
  Future<Result<List<int>>> getMonthlyReport(String pid, String month) =>
      _guard(() => getBytes('${_p(pid)}/report', queryParameters: {'month': month}));

  // ── Staff ──
  Future<Result<StaffCareToday>> staffToday() =>
      _guard(() async => StaffCareToday.fromJson(await getJson('/staff/care/today')));

  Future<Result<CareTask>> markTaskDone(
    String taskId, {
    Map<String, dynamic>? value,
    String? notes,
    List<String> photoFileIds = const [],
  }) =>
      _guard(() async => CareTask.fromJson(await postJson('/staff/care/tasks/$taskId/done', data: {
            'value': ?value,
            if (notes != null && notes.isNotEmpty) 'notes': notes,
            if (photoFileIds.isNotEmpty) 'photo_file_ids': photoFileIds,
          })));

  Future<Result<CareTask>> skipTask(String taskId, String reason) => _guard(() async =>
      CareTask.fromJson(await postJson('/staff/care/tasks/$taskId/skip', data: {'reason': reason})));

  Future<Result<CareReport>> saveDailyReport(Map<String, dynamic> body) =>
      _guard(() async => CareReport.fromJson(await putJson('/staff/care/daily-report', data: body)));

  /// "New from the family" feed. Opening it marks items seen (not read).
  Future<Result<ClientUpdatesFeed>> clientUpdates({String? placementId, bool unreadOnly = false}) =>
      _guard(() async => ClientUpdatesFeed.fromJson(await getJson('/staff/care/client-updates', queryParameters: {
            'placement_id': ?placementId,
            if (unreadOnly) 'unread': 'true',
          })));

  /// For the home card badge.
  Future<Result<int>> clientUpdatesUnreadCount() => _guard(() async {
        final j = await getJson('/staff/care/client-updates/unread-count');
        return (j['unread'] as num?)?.toInt() ?? 0;
      });

  /// "Mark as read" on a client update (CARE_PLAN, FOOD_PROFILE, MENU,
  /// MEAL_FEEDBACK, INSTRUCTION) — the type and id come from the item.
  Future<Result<void>> acknowledgeUpdate(String type, String id) =>
      _guard(() => postJson('/staff/care/client-updates/$type/$id/ack'));

  // ── Cook: food profile ──
  /// Client: the household profile + suggestions from repeated feedback.
  Future<Result<ClientFoodProfileView>> getClientFoodProfile() =>
      _guard(() async => ClientFoodProfileView.fromJson(await getJson('/client/food-profile')));

  Future<Result<ClientFoodProfileView>> saveClientFoodProfile(FoodProfile profile) =>
      _guard(() async => ClientFoodProfileView.fromJson(await putJson('/client/food-profile', data: profile.toJson())));

  /// The cook's (and RM's) way to read the household profile.
  Future<Result<FoodProfile?>> getPlacementFoodProfile(String pid) => _guard(() async {
        final j = await getJson('${_p(pid)}/food-profile');
        return j['profile'] is Map<String, dynamic> ? FoodProfile.fromJson(j['profile'] as Map<String, dynamic>) : null;
      });

  // ── Cook: menu ──
  /// [week] is "2026-W42" or any date in the week; default this week.
  Future<Result<MenuWeek>> getMenu(String pid, {String? week}) =>
      _guard(() async => MenuWeek.fromJson(await getJson('${_p(pid)}/menu', queryParameters: {'week': ?week})));

  /// Client sets slots: `{ date, meal, dishes, special_instruction?, servings? }`;
  /// `dishes: []` clears a slot.
  Future<Result<MenuWeek>> saveMenu(String pid, List<Map<String, dynamic>> items) =>
      _guard(() async => MenuWeek.fromJson(await putJson('${_p(pid)}/menu', data: {'items': items})));

  Future<Result<void>> approveMenu(String menuId) => _guard(() => postJson('/client/menu/$menuId/approve'));

  Future<Result<void>> rejectMenu(String menuId, String reason) =>
      _guard(() => postJson('/client/menu/$menuId/reject', data: {'reason': reason}));

  /// Cook: `{ date, meal, dishes, notes? }`. A slot the family set → 400.
  Future<Result<void>> suggestMenu(String pid, List<Map<String, dynamic>> items) =>
      _guard(() => postJson('/staff/care/cook/menu-suggestions', data: {'placement_id': pid, 'items': items}));

  // ── Cook: meals ──
  Future<Result<CookToday>> cookToday() => _guard(() async => CookToday.fromJson(await getJson('/staff/care/cook/today')));

  /// Logging the same meal again replaces it.
  Future<Result<MealLog>> logMeal({
    required String pid,
    required String meal,
    required List<LoggedDish> dishes,
    String? date,
    int? servings,
    String? notes,
  }) =>
      _guard(() async => MealLog.fromJson(await postJson('/staff/care/cook/meals', data: {
            'placement_id': pid,
            'date': ?date,
            'meal': meal,
            'dishes': [for (final d in dishes) d.toJson()],
            'servings': ?servings,
            'notes': ?notes,
          })));

  Future<Result<MealsView>> getMeals(String pid, {String? from, String? to}) => _guard(() async =>
      MealsView.fromJson(await getJson('${_p(pid)}/meals', queryParameters: {'from': ?from, 'to': ?to})));

  Future<Result<void>> rateMeal(String mealId, {required int rating, List<String> tags = const [], String? comment}) =>
      _guard(() => postJson('/client/meals/$mealId/feedback', data: {
            'rating': rating,
            'tags': tags,
            if (comment != null && comment.isNotEmpty) 'comment': comment,
          }));

  // ── Instructions ──
  Future<Result<List<Instruction>>> getInstructions(String pid, {String? status}) => _guard(() async {
        final j = await getJson('${_p(pid)}/instructions', queryParameters: {'status': ?status});
        return _instructions(j);
      });

  /// Client: `{ text?, voice_file_id?, kind, due_at?, recurrence? }` — at
  /// least text or a voice note.
  Future<Result<Instruction>> createInstruction(String pid, Map<String, dynamic> body) =>
      _guard(() async => Instruction.fromJson(await postJson('${_p(pid)}/instructions', data: body)));

  Future<Result<void>> cancelInstruction(String id) => _guard(() => postJson('/client/instructions/$id/cancel'));

  /// Staff: every instruction across their active placements (not cancelled).
  Future<Result<List<Instruction>>> staffInstructions({String? status}) => _guard(() async =>
      _instructions(await getJson('/staff/care/instructions', queryParameters: {'status': ?status})));

  /// "Got it".
  Future<Result<void>> acknowledgeInstruction(String id) => _guard(() => postJson('/staff/care/instructions/$id/ack'));

  Future<Result<void>> completeInstruction(String id, {String? note}) => _guard(() =>
      postJson('/staff/care/instructions/$id/done', data: {if (note != null && note.isNotEmpty) 'note': note}));

  /// "Not my job" — opens a Right-to-Refuse case for the RM.
  Future<Result<void>> refuseInstruction(String id, String reason) =>
      _guard(() => postJson('/staff/care/instructions/$id/refuse', data: {'reason': reason}));

  static List<Instruction> _instructions(Map<String, dynamic> j) => [
        for (final e in (j['items'] as List?) ?? const [])
          if (e is Map<String, dynamic>) Instruction.fromJson(e),
      ];

  // ── Files ──
  /// Upload first, then send the returned id. kind: PHOTO / PRESCRIPTION / VOICE.
  Future<Result<CareFile>> uploadFile({
    required String placementId,
    required String kind,
    required String path,
    String? filename,
  }) =>
      _guard(() async => CareFile.fromJson(await uploadMultipart(
            '/care-files',
            formData: FormData.fromMap({
              'placement_id': placementId,
              'kind': kind,
              // The backend checks the part's content type, so it must be set.
              'file': await MultipartFile.fromFile(
                path,
                filename: filename,
                contentType: DioMediaType.parse(careMimeFor(filename ?? path)),
              ),
            }),
          )));

  /// A stored file's bytes — sent with the Bearer token (there are no public links).
  Future<Result<List<int>>> fileBytes(String fileId) => _guard(() => getBytes('/care-files/$fileId'));
}

/// MIME type for the file kinds `/care-files` accepts.
String careMimeFor(String name) => switch (name.split('.').last.toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      'mp3' => 'audio/mpeg',
      'm4a' => 'audio/mp4',
      'aac' => 'audio/aac',
      'ogg' => 'audio/ogg',
      'webm' => 'audio/webm',
      'wav' => 'audio/wav',
      _ => 'application/octet-stream',
    };

final careApiProvider =Provider<CareApi>((ref) => CareApi(ref.watch(dioClientProvider)));
