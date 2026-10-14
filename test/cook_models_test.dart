import 'package:flutter_test/flutter_test.dart';
import 'package:homegennyapp/features/care/domain/cook_models.dart';

void main() {
  final profileJson = <String, dynamic>{
    'id': 'fp-1',
    'version': 2,
    'diet_type': 'VEG',
    'allergies': ['Peanuts'],
    'spice_level': 3,
    'salt': 'NORMAL',
    'oil': 'NORMAL',
    'health_conditions': ['DIABETIC'],
    'cuisines': ['North Indian'],
    'dislikes': null,
    'family_size': 4,
    'notes': null,
    'changes': ['Spice level: 4 → 3'],
  };

  group('FoodProfile', () {
    test('decodes plain-string changes and round-trips', () {
      final p = FoodProfile.fromJson(profileJson);
      expect(p.changes, ['Spice level: 4 → 3']);
      final body = p.toJson();
      expect(body['diet_type'], 'VEG');
      expect(body['spice_level'], 3);
      expect(body['allergies'], ['Peanuts']);
    });

    test('"Yes" on a suggestion makes exactly that one change', () {
      final p = FoodProfile.fromJson(profileJson);
      const s = FeedbackSuggestion(tag: 'TOO_SPICY', times: 3, suggestion: 'Lower spice level from 3 to 2?');
      final next = s.applyTo(p)!;
      expect(next.spiceLevel, 2);
      expect(next.salt, 'NORMAL');
      expect(next.allergies, ['Peanuts']);
      // The original is untouched.
      expect(p.spiceLevel, 3);

      expect(const FeedbackSuggestion(tag: 'TOO_SALTY', times: 3, suggestion: '').applyTo(p)!.salt, 'LOW');
      expect(const FeedbackSuggestion(tag: 'OILY', times: 3, suggestion: '').applyTo(p)!.oil, 'LOW');
      expect(const FeedbackSuggestion(tag: 'COLD', times: 3, suggestion: '').applyTo(p), isNull);
    });
  });

  test('menu dishes accept both strings and {name, notes}', () {
    final m = MenuItem.fromJson({
      'id': 'm-1',
      'date': '2026-10-14',
      'meal': 'LUNCH',
      'status': 'SUGGESTED',
      'dishes': ['Dal', {'name': 'Roti', 'notes': '2 each'}],
      'suggested_by_cook': true,
      'health_warnings': ['diabetic: kheer'],
    });
    expect(m.dishText, 'Dal, Roti (2 each)');
    expect(m.awaitingApproval, isTrue);
    expect(m.healthWarnings.single, 'diabetic: kheer');
    expect(m.dishes[1].toJson(), {'name': 'Roti', 'notes': '2 each'});
    expect(m.dishes[0].toJson(), 'Dal');
  });

  test('cook today always shows all four meals', () {
    final today = CookToday.fromJson({
      'date': '2026-10-13',
      'placements': [
        {
          'placement_id': 'p-1',
          'client': {'name': 'Sharma family'},
          'food_profile': profileJson,
          'meals': [
            {
              'meal': 'DINNER',
              'menu': {'id': 'm', 'date': '2026-10-13', 'meal': 'DINNER', 'status': 'PLANNED', 'dishes': ['Khichdi'], 'special_instruction': 'Less spicy'},
              'log': null,
            },
          ],
          'rating': {'avg_7d': 4.2, 'count_7d': 5, 'avg_30d': 4.0, 'count_30d': 12},
        },
      ],
    });
    final p = today.placements.single;
    expect(p.meals.map((m) => m.meal), ['BREAKFAST', 'LUNCH', 'SNACKS', 'DINNER']);
    expect(p.meals.last.menu?.specialInstruction, 'Less spicy');
    expect(p.meals.first.menu, isNull);
    expect(p.rating.avg7d, 4.2);
    expect(p.foodProfile?.allergies, ['Peanuts']);
  });

  test('meal log: photos come from dishes; feedback decodes', () {
    final m = MealLog.fromJson({
      'id': 'l-1',
      'date': '2026-10-13',
      'meal': 'LUNCH',
      'dishes': [
        {'name': 'Dal', 'spice_level': 2, 'photo_file_id': 'f-1'},
        {'name': 'Rice'},
      ],
      'feedback': {'rating': 4, 'tags': ['LESS_SALT'], 'comment': 'Nice'},
    });
    expect(m.photoFileIds, ['f-1']);
    expect(m.feedback?.rating, 4);
    expect(const LoggedDish(name: 'Rice').toJson(), {'name': 'Rice'});
  });
}
