import 'package:flutter/material.dart';

enum TrainingCategory {
  chest('胸', 'CHEST', Color(0xFFEEF0DE), Color(0xFF7E8D4A)),
  shoulder('肩', 'SHOULDERS', Color(0xFFEEE8DF), Color(0xFFA58C69)),
  back('背', 'BACK', Color(0xFFE5ECE8), Color(0xFF6D8E7C)),
  legs('腿', 'LEGS', Color(0xFFE8EBF1), Color(0xFF7C8CA1)),
  arms('臂', 'ARMS', Color(0xFFF1E7E0), Color(0xFFB58D74)),
  abs('腹', 'ABS', Color(0xFFF2ECD9), Color(0xFFAB975E)),
  indulgence('纵', 'CHEAT DAY', Color(0xFFEEEAEF), Color(0xFF9A8B9D));

  const TrainingCategory(this.label, this.english, this.tint, this.accent);

  final String label;
  final String english;
  final Color tint;
  final Color accent;

  bool get isTraining => this != indulgence;
  String get displayName => isTraining ? '$label部训练' : '放纵日';

  static Iterable<TrainingCategory> get training =>
      values.where((category) => category.isTraining);

  // Keep the original persisted ID so installed records remain compatible.
  String get storageKey => this == indulgence ? 'mixed' : name;

  static TrainingCategory fromStorage(String value) =>
      value == 'mixed' ? indulgence : values.byName(value);
}

class ExerciseDefinition {
  const ExerciseDefinition(this.id, this.category, this.name);

  final String id;
  final TrainingCategory category;
  final String name;
}

abstract final class ExerciseCatalog {
  // IDs are persisted independently of labels for future per-exercise trends.
  static const all = [
    ExerciseDefinition(
        'chest_barbell_bench_press', TrainingCategory.chest, '杠铃卧推'),
    ExerciseDefinition(
        'chest_incline_dumbbell_press', TrainingCategory.chest, '哑铃上斜卧推'),
    ExerciseDefinition('chest_machine_press', TrainingCategory.chest, '固定器械推胸'),
    ExerciseDefinition('chest_low_cable_fly', TrainingCategory.chest, '绳索夹下胸'),
    ExerciseDefinition(
        'chest_machine_incline_press', TrainingCategory.chest, '器械推上胸'),
    ExerciseDefinition(
        'chest_machine_decline_press', TrainingCategory.chest, '器械推下胸'),
    ExerciseDefinition('chest_pec_deck', TrainingCategory.chest, '蝴蝶机夹胸'),
    ExerciseDefinition(
        'chest_smith_flat_press', TrainingCategory.chest, '史密斯平板卧推'),
    ExerciseDefinition(
        'chest_smith_incline_press', TrainingCategory.chest, '史密斯上斜卧推'),
    ExerciseDefinition(
        'chest_parallel_bar_dip', TrainingCategory.chest, '双杠臂屈伸'),
    ExerciseDefinition('back_pull_up', TrainingCategory.back, '引体向上'),
    ExerciseDefinition(
        'back_assisted_pull_up', TrainingCategory.back, '辅助引体向上'),
    ExerciseDefinition(
        'back_wide_overhand_pulldown', TrainingCategory.back, '宽距正握高位下拉'),
    ExerciseDefinition(
        'back_wide_neutral_pulldown', TrainingCategory.back, '宽距对握高位下拉'),
    ExerciseDefinition(
        'back_close_neutral_pulldown', TrainingCategory.back, '窄距对握高位下拉'),
    ExerciseDefinition(
        'back_seated_close_row', TrainingCategory.back, '坐姿窄距划船'),
    ExerciseDefinition('back_scissor_row', TrainingCategory.back, '大剪刀'),
    ExerciseDefinition(
        'shoulder_seated_dumbbell_press', TrainingCategory.shoulder, '坐姿哑铃推肩'),
    ExerciseDefinition(
        'shoulder_seated_smith_press', TrainingCategory.shoulder, '坐姿史密斯推肩'),
    ExerciseDefinition(
        'shoulder_cable_y_raise', TrainingCategory.shoulder, '绳索Y字侧平举'),
    ExerciseDefinition(
        'shoulder_cable_face_pull', TrainingCategory.shoulder, '绳索面拉'),
    ExerciseDefinition(
        'shoulder_standing_fly', TrainingCategory.shoulder, '站姿飞鸟'),
    ExerciseDefinition(
        'shoulder_reverse_pec_deck', TrainingCategory.shoulder, '蝴蝶机反向飞鸟'),
    ExerciseDefinition(
        'legs_bulgarian_split_squat', TrainingCategory.legs, '保加利亚深蹲'),
    ExerciseDefinition('legs_smith_squat', TrainingCategory.legs, '史密斯杠铃深蹲'),
    ExerciseDefinition('legs_leg_press', TrainingCategory.legs, '倒蹬'),
    ExerciseDefinition('legs_machine_adduction', TrainingCategory.legs, '器械内收'),
    ExerciseDefinition('legs_machine_abduction', TrainingCategory.legs, '器械外展'),
    ExerciseDefinition(
        'legs_quadriceps_curl', TrainingCategory.legs, '器械腿弯举—股四'),
    ExerciseDefinition(
        'legs_hamstring_curl', TrainingCategory.legs, '器械腿弯举—腘绳肌'),
    ExerciseDefinition('arms_cable_pushdown', TrainingCategory.arms, '绳索下拉'),
    ExerciseDefinition('arms_biceps_curl', TrainingCategory.arms, '二头弯举'),
    ExerciseDefinition('abs_hanging_leg_raise', TrainingCategory.abs, '悬垂举腿'),
    ExerciseDefinition('abs_weighted_crunch', TrainingCategory.abs, '负重卷腹'),
    ExerciseDefinition('abs_cable_crunch', TrainingCategory.abs, '龙门架卷腹'),
  ];

  static Iterable<ExerciseDefinition> forCategory(TrainingCategory category) =>
      all.where((exercise) => exercise.category == category);

  static ExerciseDefinition? findById(String? id) {
    for (final exercise in all) {
      if (exercise.id == id) return exercise;
    }
    return null;
  }

  static ExerciseDefinition? findByName(String name) {
    for (final exercise in all) {
      if (exercise.name == name.trim()) return exercise;
    }
    return null;
  }
}
