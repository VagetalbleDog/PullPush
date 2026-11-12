import 'package:flutter/material.dart';

import '../models/workout.dart';
import '../theme.dart';
import 'common.dart';

enum WorkoutAction { edit, delete }

class WorkoutDetail extends StatelessWidget {
  const WorkoutDetail({super.key, required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final category = workout.category;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 14, 20),
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Eyebrow(workout.isTraining
                      ? 'ANOTHER DAY, ANOTHER STEP'
                      : 'ENJOY YOUR DAY'),
                  const SizedBox(height: 7),
                  Text('${workout.date.year} 年 ${friendlyDate(workout.date)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted)),
                ])),
            IconButton(
                onPressed: () => Navigator.pop(context),
                tooltip: '关闭',
                icon: const Icon(Icons.close_rounded, size: 21)),
          ]),
        ),
        Flexible(
            child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 25),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                  color: category.tint,
                  borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Text(category.label,
                    style: const TextStyle(
                        fontSize: 58,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                        height: 1.2)),
                const SizedBox(width: 21),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Eyebrow(category.english, color: category.accent),
                      const SizedBox(height: 8),
                      Text(workout.isTraining ? '训练已记录' : '放纵日已记录',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(workout.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.muted)),
                    ])),
                const Icon(Icons.check_circle_outline_rounded,
                    color: AppColors.forest, size: 20),
              ]),
            ),
            if (!workout.isTraining) ...[
              const SizedBox(height: 16),
              const Text('放纵日不计入训练天数、组数、部位和容量统计。',
                  style: TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
            if (workout.exercises.isNotEmpty) ...[
              const SizedBox(height: 25),
              Row(children: [
                Text(workout.isTraining ? '动作明细' : '历史动作明细',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(
                    workout.isTraining
                        ? '${workout.totalSets} 组 · ${formatVolume(workout.totalVolume)} kg 总容量'
                        : '仅保留原记录，不计入训练统计',
                    style:
                        const TextStyle(fontSize: 10, color: AppColors.muted)),
              ]),
              const SizedBox(height: 12),
              for (var i = 0; i < workout.exercises.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${i + 1}'.padLeft(2, '0'),
                            style: numberStyle(12, color: AppColors.muted)),
                        const SizedBox(width: 13),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(workout.exercises[i].name,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text(_exerciseSummary(workout.exercises[i]),
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.muted)),
                            ])),
                      ]),
                ),
            ],
            const SizedBox(height: 23),
            Text(workout.isTraining ? '训练备注' : '放纵日备注',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                  color: const Color(0xFFF6F7F0),
                  borderRadius: BorderRadius.circular(12)),
              child: SelectableText(
                workout.note.isEmpty
                    ? (workout.isTraining
                        ? '没有留下备注，但这一次训练已经被记住。'
                        : '没有留下备注，今天的放纵日已经记下。')
                    : workout.note,
                style: TextStyle(
                    fontSize: 13,
                    height: 1.9,
                    color:
                        workout.note.isEmpty ? AppColors.muted : AppColors.ink),
              ),
            ),
          ]),
        )),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 28, 22),
          child: Row(children: [
            TextButton.icon(
              key: const Key('delete-workout'),
              onPressed: () => Navigator.pop(context, WorkoutAction.delete),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              icon: const Icon(Icons.delete_outline_rounded, size: 17),
              label: const Text('删除', style: TextStyle(fontSize: 12)),
            ),
            const Spacer(),
            FilledButton.icon(
              key: const Key('edit-workout'),
              onPressed: () => Navigator.pop(context, WorkoutAction.edit),
              icon: const Icon(Icons.edit_outlined, size: 17),
              label: const Text('编辑记录'),
            ),
          ]),
        ),
      ],
    );
  }

  String _exerciseSummary(Exercise exercise) => [
        '${exercise.sets} 组',
        if (exercise.reps != null)
          '${exercise.weightMode == WeightMode.dropSet ? '每级' : '每组'} ${exercise.reps} 次',
        if (exercise.weightMode == WeightMode.dropSet)
          '递减重量 ${exercise.dropWeights.map(formatWeight).join(' → ')} kg'
        else if (exercise.weight != null)
          '标准重量 ${formatWeight(exercise.weight!)} kg',
      ].join('  ·  ');
}

String formatWeight(double value) =>
    value == value.roundToDouble() ? '${value.toInt()}' : '$value';

String formatVolume(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}
