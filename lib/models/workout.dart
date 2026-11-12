import 'training_catalog.dart';

export 'training_catalog.dart';

String dateKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String weekdayLabel(DateTime date) =>
    ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'][date.weekday - 1];

String friendlyDate(DateTime date) =>
    '${date.month} 月 ${date.day} 日 · ${weekdayLabel(date)}';

List<DateTime> calendarDays(DateTime month) {
  final first = DateTime(month.year, month.month);
  final start = DateTime(first.year, first.month, 2 - first.weekday);
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  final count = ((first.weekday - 1 + daysInMonth) / 7).ceil() * 7;
  // Construct civil dates instead of adding 24 hours across daylight savings.
  return List.generate(
      count, (i) => DateTime(start.year, start.month, start.day + i));
}

enum WeightMode { standard, dropSet }

class Exercise {
  Exercise({
    required this.name,
    required this.sets,
    this.reps,
    this.weight,
    String? catalogId,
    this.weightMode = WeightMode.standard,
    List<double> dropWeights = const [],
  })  : _catalogId = catalogId,
        dropWeights = List.unmodifiable(dropWeights) {
    if (name.trim().isEmpty ||
        sets < 1 ||
        sets > 999 ||
        (reps != null && (reps! < 1 || reps! > 9999)) ||
        (weight != null && !_validWeight(weight!))) {
      throw const FormatException('Invalid exercise');
    }
    if (weightMode == WeightMode.dropSet) {
      if (dropWeights.length < 2 ||
          dropWeights.any((value) => !_validWeight(value))) {
        throw const FormatException(
            'Drop sets need at least two valid weights');
      }
      for (var index = 1; index < dropWeights.length; index++) {
        if (dropWeights[index] >= dropWeights[index - 1]) {
          throw const FormatException(
              'Drop weights must be strictly descending');
        }
      }
    }
  }

  static bool _validWeight(double value) =>
      value.isFinite && value >= 0 && value <= 9999;

  final String name;
  final int sets;
  final int? reps;
  final double? weight;
  final String? _catalogId;
  final WeightMode weightMode;
  final List<double> dropWeights;

  ExerciseDefinition? get definition => _catalogId == null
      ? ExerciseCatalog.findByName(name)
      : ExerciseCatalog.findById(_catalogId);
  String? get catalogId => _catalogId ?? definition?.id;

  double? get peakWeight =>
      weightMode == WeightMode.dropSet ? dropWeights.first : weight;

  // For drop sets, reps apply to each weight stage within each set.
  double get volume =>
      sets *
      (reps ?? 0) *
      (weightMode == WeightMode.dropSet
          ? dropWeights.fold(0.0, (sum, value) => sum + value)
          : weight ?? 0);

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': sets,
        'reps': reps,
        'weight': weight,
        if (catalogId != null) 'catalogId': catalogId,
        if (weightMode == WeightMode.dropSet) ...{
          'weightMode': weightMode.name,
          'dropWeights': dropWeights,
        },
      };

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final sets = json['sets'] as int;
    final reps = json['reps'] as int?;
    final weight = (json['weight'] as num?)?.toDouble();
    final catalogId = json['catalogId'] as String?;
    final modeName = json['weightMode'] as String? ?? 'standard';
    if (!WeightMode.values.any((mode) => mode.name == modeName)) {
      throw const FormatException('Invalid weight mode');
    }
    final weightMode = WeightMode.values.byName(modeName);
    final dropWeights = (json['dropWeights'] as List<dynamic>? ?? [])
        .map((value) => (value as num).toDouble())
        .toList();
    return Exercise(
        name: name,
        sets: sets,
        reps: reps,
        weight: weightMode == WeightMode.standard ? weight : null,
        catalogId: catalogId,
        weightMode: weightMode,
        dropWeights: dropWeights);
  }
}

class Workout {
  Workout({
    required DateTime date,
    required this.category,
    this.note = '',
    List<Exercise> exercises = const [],
  })  : date = dateOnly(date),
        exercises = List.unmodifiable(exercises);

  final DateTime date;
  final TrainingCategory category;
  final String note;
  final List<Exercise> exercises;

  String get key => dateKey(date);
  bool get isTraining => category.isTraining;
  int get totalSets =>
      isTraining ? exercises.fold(0, (total, item) => total + item.sets) : 0;
  double get totalVolume =>
      isTraining ? exercises.fold(0, (total, item) => total + item.volume) : 0;

  String get summary {
    if (!isTraining) {
      return note.trim().isEmpty
          ? '今天是放纵日，享受一下生活。'
          : note.trim().split('\n').first;
    }
    if (exercises.isNotEmpty) return '${exercises.length} 个动作 · $totalSets 组';
    return note.trim().isEmpty ? '今天也有认真训练' : note.trim().split('\n').first;
  }

  Map<String, dynamic> toJson() => {
        'date': key,
        'category': category.storageKey,
        'note': note,
        'exercises': exercises.map((item) => item.toJson()).toList(),
      };

  factory Workout.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'] as String;
    final date = DateTime.parse(rawDate);
    if (dateKey(date) != rawDate) {
      throw const FormatException('Invalid workout date');
    }
    return Workout(
      date: date,
      category: TrainingCategory.fromStorage(json['category'] as String),
      note: json['note'] as String? ?? '',
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .map((item) => Exercise.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
