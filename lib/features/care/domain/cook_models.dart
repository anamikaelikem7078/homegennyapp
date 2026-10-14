/// Cook: household food profile, weekly menu, meal log and ratings.
library;

Map<String, dynamic> _map(Object? v) => v is Map<String, dynamic> ? v : const {};
List<Map<String, dynamic>> _maps(Object? v) =>
    [for (final e in (v is List ? v : const [])) if (e is Map<String, dynamic>) e];
List<String> _strings(Object? v) => [for (final e in (v is List ? v : const [])) '$e'];
String? _str(Object? v) => v == null || '$v'.trim().isEmpty ? null : '$v';
num? _num(Object? v) => v is num ? v : num.tryParse('${v ?? ''}');

abstract final class CookEnums {
  static const diets = ['VEG', 'EGG', 'NON_VEG', 'JAIN', 'VEGAN'];
  static const meals = ['BREAKFAST', 'LUNCH', 'SNACKS', 'DINNER'];

  /// Health conditions the backend checks menus against (others are kept
  /// and shown, but raise no warning).
  static const healthConditions = ['DIABETIC', 'LOW_SODIUM', 'LOW_FAT', 'NO_ONION_GARLIC'];
  static const feedbackTags = [
    'PERFECT', 'TOO_SPICY', 'LESS_SPICY', 'TOO_SALTY', 'LESS_SALT',
    'OILY', 'UNDERCOOKED', 'OVERCOOKED', 'COLD', 'SMALL_PORTION',
  ];
}

/// The household's food profile — belongs to the family, survives a change
/// of cook.
class FoodProfile {
  FoodProfile({
    this.id,
    this.version = 0,
    this.dietType,
    List<String>? allergies,
    this.spiceLevel,
    this.salt,
    this.oil,
    List<String>? healthConditions,
    List<String>? cuisines,
    this.dislikes,
    this.familySize,
    this.notes,
    this.changes = const [],
  })  : allergies = allergies ?? [],
        healthConditions = healthConditions ?? [],
        cuisines = cuisines ?? [];

  factory FoodProfile.fromJson(Map<String, dynamic> j) => FoodProfile(
        id: _str(j['id']),
        version: _num(j['version'])?.toInt() ?? 0,
        dietType: _str(j['diet_type']),
        allergies: _strings(j['allergies']),
        spiceLevel: _num(j['spice_level'])?.toInt(),
        salt: _str(j['salt']),
        oil: _str(j['oil']),
        healthConditions: _strings(j['health_conditions']),
        cuisines: _strings(j['cuisines']),
        dislikes: _str(j['dislikes']),
        familySize: _num(j['family_size'])?.toInt(),
        notes: _str(j['notes']),
        // Profile changes are plain strings, e.g. "Spice level: 4 → 2".
        changes: _strings(j['changes']),
      );

  String? id;
  int version;
  String? dietType;
  List<String> allergies;

  /// 1 (mild) to 5 (very spicy).
  int? spiceLevel;

  /// LOW / NORMAL.
  String? salt;
  String? oil;
  List<String> healthConditions;
  List<String> cuisines;
  String? dislikes;
  int? familySize;
  String? notes;
  final List<String> changes;

  FoodProfile copy() => FoodProfile.fromJson({...toJson(), 'id': id, 'version': version, 'changes': changes});

  Map<String, dynamic> toJson() => {
        'diet_type': dietType,
        'allergies': allergies,
        'spice_level': spiceLevel,
        'salt': salt,
        'oil': oil,
        'health_conditions': healthConditions,
        'cuisines': cuisines,
        'dislikes': dislikes ?? '',
        'family_size': familySize,
        'notes': notes ?? '',
      };
}

/// "Same complaint 3× in 14 days" → a suggested profile change.
class FeedbackSuggestion {
  const FeedbackSuggestion({required this.tag, required this.times, required this.suggestion});
  factory FeedbackSuggestion.fromJson(Map<String, dynamic> j) => FeedbackSuggestion(
        tag: '${j['tag'] ?? ''}',
        times: _num(j['times'])?.toInt() ?? 0,
        suggestion: '${j['suggestion'] ?? ''}',
      );
  final String tag;
  final int times;
  final String suggestion;

  /// The one change "Yes" makes to [p], or null if this tag has no
  /// matching profile change.
  FoodProfile? applyTo(FoodProfile p) {
    final next = p.copy();
    final lvl = p.spiceLevel;
    switch (tag) {
      case 'TOO_SPICY' when lvl != null && lvl > 1:
        next.spiceLevel = lvl - 1;
      case 'LESS_SPICY' when lvl != null && lvl < 5:
        next.spiceLevel = lvl + 1;
      case 'TOO_SALTY':
        next.salt = 'LOW';
      case 'OILY':
        next.oil = 'LOW';
      default:
        return null;
    }
    return next;
  }
}

class ClientFoodProfileView {
  const ClientFoodProfileView({this.profile, this.suggestions = const []});
  factory ClientFoodProfileView.fromJson(Map<String, dynamic> j) => ClientFoodProfileView(
        profile: j['profile'] is Map<String, dynamic> ? FoodProfile.fromJson(j['profile'] as Map<String, dynamic>) : null,
        suggestions: [for (final s in _maps(j['feedback_suggestions'])) FeedbackSuggestion.fromJson(s)],
      );
  final FoodProfile? profile;
  final List<FeedbackSuggestion> suggestions;
}

// ── Menu ──────────────────────────────────────────────────────────────────

class MenuDish {
  const MenuDish({required this.name, this.notes});
  factory MenuDish.fromJson(Object? j) => j is Map<String, dynamic>
      ? MenuDish(name: '${j['name'] ?? ''}', notes: _str(j['notes']))
      : MenuDish(name: '${j ?? ''}');
  final String name;
  final String? notes;

  Object toJson() => notes == null ? name : {'name': name, 'notes': notes};
  @override
  String toString() => notes == null ? name : '$name ($notes)';
}

abstract final class MenuStatus {
  static const planned = 'PLANNED';
  static const suggested = 'SUGGESTED';
  static const approved = 'APPROVED';
  static const rejected = 'REJECTED';
}

class MenuItem {
  const MenuItem({
    required this.id,
    required this.date,
    required this.meal,
    required this.status,
    this.dishes = const [],
    this.specialInstruction,
    this.servings,
    this.rejectReason,
    this.suggestedByCook = false,
    this.changes = const [],
    this.healthWarnings = const [],
  });

  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
        id: '${j['id'] ?? ''}',
        date: '${j['date'] ?? ''}',
        meal: '${j['meal'] ?? ''}',
        status: '${j['status'] ?? ''}',
        dishes: [for (final d in (j['dishes'] is List ? j['dishes'] as List : const [])) MenuDish.fromJson(d)],
        specialInstruction: _str(j['special_instruction']),
        servings: _num(j['servings'])?.toInt(),
        rejectReason: _str(j['reject_reason']),
        suggestedByCook: j['suggested_by_cook'] == true,
        changes: _strings(j['changes']),
        healthWarnings: _strings(j['health_warnings']),
      );

  final String id;
  final String date;
  final String meal;

  /// PLANNED (client) / SUGGESTED (cook) / APPROVED / REJECTED.
  final String status;
  final List<MenuDish> dishes;
  final String? specialInstruction;
  final int? servings;
  final String? rejectReason;
  final bool suggestedByCook;
  final List<String> changes;

  /// A yellow note only — never blocks.
  final List<String> healthWarnings;

  bool get awaitingApproval => status == MenuStatus.suggested;
  String get dishText => dishes.map((d) => d.toString()).join(', ');
}

class MenuWeek {
  const MenuWeek({required this.weekStart, required this.weekEnd, this.items = const []});
  factory MenuWeek.fromJson(Map<String, dynamic> j) => MenuWeek(
        weekStart: '${j['week_start'] ?? ''}',
        weekEnd: '${j['week_end'] ?? ''}',
        items: [for (final m in _maps(j['items'])) MenuItem.fromJson(m)],
      );
  final String weekStart;
  final String weekEnd;
  final List<MenuItem> items;

  MenuItem? slot(String date, String meal) =>
      items.where((m) => m.date == date && m.meal == meal).firstOrNull;
}

// ── Meals ─────────────────────────────────────────────────────────────────

class LoggedDish {
  const LoggedDish({required this.name, this.spiceLevel, this.photoFileId});
  factory LoggedDish.fromJson(Map<String, dynamic> j) => LoggedDish(
        name: '${j['name'] ?? ''}',
        spiceLevel: _num(j['spice_level'])?.toInt(),
        photoFileId: _str(j['photo_file_id']),
      );
  final String name;
  final int? spiceLevel;
  final String? photoFileId;

  Map<String, dynamic> toJson() => {'name': name, 'spice_level': ?spiceLevel, 'photo_file_id': ?photoFileId};
}

class MealFeedback {
  const MealFeedback({required this.rating, this.tags = const [], this.comment});
  factory MealFeedback.fromJson(Map<String, dynamic> j) => MealFeedback(
        rating: _num(j['rating'])?.toInt() ?? 0,
        tags: _strings(j['tags']),
        comment: _str(j['comment']),
      );
  final int rating;
  final List<String> tags;
  final String? comment;
}

class MealLog {
  const MealLog({
    required this.id,
    required this.date,
    required this.meal,
    this.dishes = const [],
    this.servings,
    this.cookedAt,
    this.notes,
    this.feedback,
  });

  factory MealLog.fromJson(Map<String, dynamic> j) => MealLog(
        id: '${j['id'] ?? ''}',
        date: '${j['date'] ?? ''}',
        meal: '${j['meal'] ?? ''}',
        dishes: [for (final d in _maps(j['dishes'])) LoggedDish.fromJson(d)],
        servings: _num(j['servings'])?.toInt(),
        cookedAt: DateTime.tryParse('${j['cooked_at'] ?? ''}')?.toLocal(),
        notes: _str(j['notes']),
        feedback: j['feedback'] is Map<String, dynamic> ? MealFeedback.fromJson(j['feedback'] as Map<String, dynamic>) : null,
      );

  final String id;
  final String date;
  final String meal;
  final List<LoggedDish> dishes;
  final int? servings;
  final DateTime? cookedAt;
  final String? notes;
  final MealFeedback? feedback;

  List<String> get photoFileIds => [for (final d in dishes) if (d.photoFileId != null) d.photoFileId!];
}

class RatingStats {
  const RatingStats({this.avg7d, this.count7d = 0, this.avg30d, this.count30d = 0});
  factory RatingStats.fromJson(Map<String, dynamic> j) => RatingStats(
        avg7d: _num(j['avg_7d']),
        count7d: _num(j['count_7d'])?.toInt() ?? 0,
        avg30d: _num(j['avg_30d']),
        count30d: _num(j['count_30d'])?.toInt() ?? 0,
      );
  final num? avg7d;
  final int count7d;
  final num? avg30d;
  final int count30d;
}

class MealsView {
  const MealsView({this.items = const [], this.rating = const RatingStats()});
  factory MealsView.fromJson(Map<String, dynamic> j) => MealsView(
        items: [for (final m in _maps(j['items'])) MealLog.fromJson(m)],
        rating: RatingStats.fromJson(_map(j['rating'])),
      );
  final List<MealLog> items;
  final RatingStats rating;
}

// ── Cook's day ────────────────────────────────────────────────────────────

class CookMealSlot {
  const CookMealSlot({required this.meal, this.menu, this.log});
  final String meal;
  final MenuItem? menu;
  final MealLog? log;
}

/// One placement in `GET /staff/care/cook/today`.
class CookPlacement {
  const CookPlacement({
    required this.placementId,
    required this.clientName,
    this.clientAddress,
    this.foodProfile,
    this.meals = const [],
    this.rating = const RatingStats(),
  });

  factory CookPlacement.fromJson(Map<String, dynamic> j) {
    final client = _map(j['client']);
    final listed = {
      for (final m in _maps(j['meals']))
        '${m['meal']}': CookMealSlot(
          meal: '${m['meal']}',
          menu: m['menu'] is Map<String, dynamic> ? MenuItem.fromJson(m['menu'] as Map<String, dynamic>) : null,
          log: m['log'] is Map<String, dynamic> ? MealLog.fromJson(m['log'] as Map<String, dynamic>) : null,
        ),
    };
    return CookPlacement(
      placementId: '${j['placement_id'] ?? ''}',
      clientName: _str(client['name']) ?? 'Family',
      clientAddress: _str(client['address']),
      foodProfile: j['food_profile'] is Map<String, dynamic> ? FoodProfile.fromJson(j['food_profile'] as Map<String, dynamic>) : null,
      // The API lists only meals with a menu or a log; show all four so any
      // meal can be logged.
      meals: [for (final meal in CookEnums.meals) listed[meal] ?? CookMealSlot(meal: meal)],
      rating: RatingStats.fromJson(_map(j['rating'])),
    );
  }

  final String placementId;
  final String clientName;
  final String? clientAddress;
  final FoodProfile? foodProfile;
  final List<CookMealSlot> meals;
  final RatingStats rating;
}

class CookToday {
  const CookToday({required this.date, this.placements = const []});
  factory CookToday.fromJson(Map<String, dynamic> j) => CookToday(
        date: '${j['date'] ?? ''}',
        placements: [for (final p in _maps(j['placements'])) CookPlacement.fromJson(p)],
      );
  final String date;
  final List<CookPlacement> placements;
}
