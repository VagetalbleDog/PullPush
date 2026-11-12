import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/workout.dart';

abstract interface class WorkoutRepository {
  Future<Map<String, Workout>> load();
  Future<void> save(Map<String, Workout> workouts);
}

class PreferencesWorkoutRepository implements WorkoutRepository {
  static const storageKey = 'pullpush.workouts.v1';

  @override
  Future<Map<String, Workout>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);
    if (raw == null) return {};
    final document = jsonDecode(raw) as Map<String, dynamic>;
    if (document['version'] != 1 && document['version'] != 2) {
      throw const FormatException('Unsupported workout data version');
    }
    final entries = document['workouts'] as List<dynamic>;
    final workouts = <String, Workout>{};
    // Do not silently discard unreadable records or overwrite the original data.
    for (final entry in entries) {
      final workout = Workout.fromJson(entry as Map<String, dynamic>);
      workouts[workout.key] = workout;
    }
    return workouts;
  }

  @override
  Future<void> save(Map<String, Workout> workouts) async {
    final raw = jsonEncode({
      'version': 2,
      'workouts': workouts.values.map((item) => item.toJson()).toList(),
    });
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString(storageKey, raw)) {
      throw StateError('Could not persist workout records');
    }
  }
}
