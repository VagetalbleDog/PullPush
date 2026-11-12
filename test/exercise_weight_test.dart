import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pullpush/data/workout_repository.dart';
import 'package:pullpush/models/workout.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('exercise constructors enforce immutable and valid weight profiles', () {
    final source = [20.0, 10.0];
    final exercise = Exercise(
        name: '负重卷腹',
        sets: 3,
        weightMode: WeightMode.dropSet,
        dropWeights: source);
    source[0] = 99;
    expect(exercise.dropWeights, [20, 10]);
    expect(
        () => Exercise(
            name: '负重卷腹',
            sets: 3,
            weightMode: WeightMode.dropSet,
            dropWeights: [20]),
        throwsFormatException);
    expect(
        () => Exercise(
            name: '负重卷腹',
            sets: 3,
            weightMode: WeightMode.dropSet,
            dropWeights: [20, 30]),
        throwsFormatException);
    expect(() => Exercise(name: '负重卷腹', sets: 0, weight: 10),
        throwsFormatException);
    expect(() => Exercise(name: '负重卷腹', sets: 3, weight: double.nan),
        throwsFormatException);
    expect(Exercise(name: '负重卷腹', sets: 3, weight: 0).peakWeight, 0);
    expect(Exercise(name: '负重卷腹', sets: 3).peakWeight, isNull);
  });

  test('drop sets round-trip ordered weights and count every stage in volume',
      () {
    final raw = {
      'name': '杠铃卧推',
      'catalogId': 'chest_barbell_bench_press',
      'sets': 3,
      'reps': 10,
      'weightMode': 'dropSet',
      'dropWeights': [60.0, 40.0, 20.0],
    };
    final exercise = Exercise.fromJson(raw);
    expect(exercise.weightMode, WeightMode.dropSet);
    expect(exercise.dropWeights, [60, 40, 20]);
    expect(exercise.weight, isNull);
    expect(exercise.volume, 3600);
    expect(exercise.peakWeight, 60);
    final restored =
        Exercise.fromJson(jsonDecode(jsonEncode(exercise.toJson())));
    expect(restored.toJson(), exercise.toJson());
    expect(() => restored.dropWeights.clear(), throwsUnsupportedError);

    for (final invalid in [
      <num>[],
      [60],
      [60, 60],
      [40, 60],
      [60, -1],
      [60, double.nan],
      [10000, 20],
    ]) {
      expect(() => Exercise.fromJson({...raw, 'dropWeights': invalid}),
          throwsFormatException,
          reason: '$invalid is not a valid drop sequence');
    }
    expect(
        Exercise.fromJson({
          ...raw,
          'dropWeights': [20, 0]
        }).volume,
        600);
    expect(Exercise.fromJson({...raw, 'reps': null}).volume, 0);
    expect(() => Exercise.fromJson({...raw, 'weightMode': 'unknown'}),
        throwsFormatException);
  });

  test('repository saves weight stages in v2 and reloads their full sequence',
      () async {
    SharedPreferences.setMockInitialValues({});
    final workout = Workout(
      date: DateTime(2026, 11, 12),
      category: TrainingCategory.abs,
      exercises: [
        Exercise(
            name: '负重卷腹',
            sets: 3,
            reps: 12,
            weightMode: WeightMode.dropSet,
            dropWeights: [20, 10, 0]),
      ],
    );
    await PreferencesWorkoutRepository().save({workout.key: workout});
    final preferences = await SharedPreferences.getInstance();
    final document = jsonDecode(
        preferences.getString(PreferencesWorkoutRepository.storageKey)!);
    expect(document['version'], 2);
    final restored =
        (await PreferencesWorkoutRepository().load()).values.single;
    expect(restored.category, TrainingCategory.abs);
    expect(restored.exercises.single.dropWeights, [20, 10, 0]);
    expect(restored.exercises.single.catalogId, 'abs_weighted_crunch');
    expect(restored.totalVolume, 1080);
  });
}
