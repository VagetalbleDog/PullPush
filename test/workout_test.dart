import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pullpush/data/workout_repository.dart';
import 'package:pullpush/models/workout.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Calendar dates', () {
    test('uses complete Monday-first weeks across month and year boundaries',
        () {
      final november = calendarDays(DateTime(2026, 11));
      expect(november.length, 42);
      expect(november.first, DateTime(2026, 10, 26));
      expect(november.last, DateTime(2026, 12, 6));
      expect(november.first.weekday, DateTime.monday);
      final december = calendarDays(DateTime(2025, 12));
      expect(december.last.year, 2026);
    });

    test('handles leap years and four-week months', () {
      expect(calendarDays(DateTime(2024, 2)).contains(DateTime(2024, 2, 29)),
          isTrue);
      expect(calendarDays(DateTime(2021, 2)).length, 28);
    });

    test('normalizes times without converting the local calendar date to UTC',
        () {
      expect(dateKey(DateTime(2026, 11, 12, 23, 59)), '2026-11-12');
      expect(sameDay(DateTime(2026, 11, 12, 1), DateTime(2026, 11, 12, 23)),
          isTrue);
    });
  });

  group('Workout model', () {
    test('round-trips notes and exercises with derived totals', () {
      final workout = Workout(
        date: DateTime(2026, 11, 12, 16),
        category: TrainingCategory.chest,
        note: '今天状态不错\n下次加重',
        exercises: [
          Exercise(name: '杠铃卧推', sets: 4, reps: 10, weight: 60),
          Exercise(name: '哑铃飞鸟', sets: 3, reps: 12, weight: 12.5),
        ],
      );
      final restored =
          Workout.fromJson(jsonDecode(jsonEncode(workout.toJson())));
      expect(restored.date, DateTime(2026, 11, 12));
      expect(restored.totalSets, 7);
      expect(restored.totalVolume, 2850);
      expect(restored.summary, '2 个动作 · 7 组');
      expect(restored.note, workout.note);
      expect(() => restored.exercises.clear(), throwsUnsupportedError);
    });

    test('includes six training categories and a separate indulgence day', () {
      expect(TrainingCategory.values.map((item) => item.label),
          ['胸', '肩', '背', '腿', '臂', '腹', '纵']);
      expect(TrainingCategory.training.map((item) => item.label),
          ['胸', '肩', '背', '腿', '臂', '腹']);
      expect(TrainingCategory.indulgence.displayName, '放纵日');
      expect(TrainingCategory.indulgence.isTraining, isFalse);
    });

    test(
        'indulgence excludes legacy exercises from totals without erasing them',
        () {
      final workout = Workout.fromJson({
        'date': '2026-11-12',
        'category': 'mixed',
        'note': '今天吃顿好的\n明天继续',
        'exercises': [
          {'name': '旧版填写的动作', 'sets': 4, 'reps': 10, 'weight': 60},
        ],
      });
      expect(workout.category, TrainingCategory.indulgence);
      expect(workout.isTraining, isFalse);
      expect(workout.totalSets, 0);
      expect(workout.totalVolume, 0);
      expect(workout.summary, '今天吃顿好的');
      expect(workout.exercises.single.sets, 4);
      final restored = Workout.fromJson(workout.toJson());
      expect(restored.toJson(), workout.toJson());
      expect(restored.toJson()['category'], 'mixed');
    });

    test('an indulgence day needs no notes or exercises', () {
      final workout = Workout(
          date: DateTime(2026, 11, 12), category: TrainingCategory.indulgence);
      expect(workout.summary, '今天是放纵日，享受一下生活。');
      expect(workout.totalSets, 0);
      expect(workout.totalVolume, 0);
      expect(Workout.fromJson(workout.toJson()).category,
          TrainingCategory.indulgence);
    });

    test('rejects invalid dates and malformed exercise numbers', () {
      expect(
          () => Workout.fromJson({'date': '2026-02-30', 'category': 'chest'}),
          throwsFormatException);
      expect(() => Exercise.fromJson({'name': '卧推', 'sets': 0}),
          throwsFormatException);
      expect(() => Exercise.fromJson({'name': '卧推', 'sets': 4, 'weight': -1}),
          throwsFormatException);
    });
  });

  group('Persistent repository', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('starts empty and persists records across repository instances',
        () async {
      final repository = PreferencesWorkoutRepository();
      expect(await repository.load(), isEmpty);
      final workout = Workout(
          date: DateTime(2026, 11, 12),
          category: TrainingCategory.legs,
          note: '深蹲 4 组 80kg');
      await repository.save({workout.key: workout});
      final restored = await PreferencesWorkoutRepository().load();
      expect(restored.keys, ['2026-11-12']);
      expect(restored.values.single.note, workout.note);
      await repository.save({});
      expect(await PreferencesWorkoutRepository().load(), isEmpty);
    });

    test('does not silently erase corrupt or newer-version data', () async {
      SharedPreferences.setMockInitialValues(
          {PreferencesWorkoutRepository.storageKey: '{invalid'});
      await expectLater(
          PreferencesWorkoutRepository().load(), throwsFormatException);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(PreferencesWorkoutRepository.storageKey),
          '{invalid');
      await preferences.setString(PreferencesWorkoutRepository.storageKey,
          '{"version":3,"workouts":[]}');
      await expectLater(
          PreferencesWorkoutRepository().load(), throwsFormatException);
    });

    test(
        'reads and resaves installed legacy indulgence records without data loss',
        () async {
      final document = {
        'version': 1,
        'workouts': [
          {
            'date': '2026-11-12',
            'category': 'mixed',
            'note': '火锅日',
            'exercises': [
              {'name': '旧动作', 'sets': 3, 'reps': 12, 'weight': 20.0},
            ],
          },
          {
            'date': '2026-11-11',
            'category': 'chest',
            'note': '卧推',
            'exercises': [],
          },
        ],
      };
      SharedPreferences.setMockInitialValues({
        PreferencesWorkoutRepository.storageKey: jsonEncode(document),
      });
      final repository = PreferencesWorkoutRepository();
      final records = await repository.load();
      expect(records['2026-11-12']!.category, TrainingCategory.indulgence);
      expect(records['2026-11-12']!.exercises.single.name, '旧动作');
      expect(records['2026-11-11']!.isTraining, isTrue);
      await repository.save(records);
      final preferences = await SharedPreferences.getInstance();
      expect(
          jsonDecode(
              preferences.getString(PreferencesWorkoutRepository.storageKey)!),
          {...document, 'version': 2});
    });
  });
}
