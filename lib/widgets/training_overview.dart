import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/workout.dart';
import '../theme.dart';
import 'common.dart';
import 'workout_detail.dart';

class TrainingOverview extends StatelessWidget {
  const TrainingOverview({
    super.key,
    required this.month,
    required this.workouts,
    required this.onDayTap,
    required this.onMonthChange,
  });

  final DateTime month;
  final List<Workout> workouts;
  final ValueChanged<DateTime> onDayTap;
  final ValueChanged<int> onMonthChange;

  @override
  Widget build(BuildContext context) {
    final sorted = [...workouts]..sort((a, b) => b.date.compareTo(a.date));
    final indulgenceDays = workouts.where((item) => !item.isTraining).length;
    final maxCount = math.max(
        1,
        TrainingCategory.training
            .map(
              (category) =>
                  workouts.where((item) => item.category == category).length,
            )
            .reduce(math.max));
    return PaperPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child: Text('${month.year} 年 ${month.month} 月',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w600))),
        IconButton(
            onPressed: month.year > 1900 || month.month > 1
                ? () => onMonthChange(-1)
                : null,
            tooltip: '上个月',
            icon: const Icon(Icons.chevron_left_rounded)),
        IconButton(
            onPressed: month.year < 2100 || month.month < 12
                ? () => onMonthChange(1)
                : null,
            tooltip: '下个月',
            icon: const Icon(Icons.chevron_right_rounded)),
      ]),
      const SizedBox(height: 5),
      const Text('每一份付出，都有迹可循。',
          style: TextStyle(fontSize: 12, color: AppColors.muted)),
      const SizedBox(height: 27),
      const Eyebrow('YOUR TRAINING BALANCE'),
      const SizedBox(height: 22),
      for (final category in TrainingCategory.training)
        Padding(
          key: Key('balance-${category.name}'),
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: category.tint, borderRadius: BorderRadius.circular(8)),
              child: Text(category.label,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value:
                    workouts.where((item) => item.category == category).length /
                        maxCount,
                minHeight: 8,
                color: category.accent,
                backgroundColor: const Color(0xFFF1F2EB),
              ),
            )),
            const SizedBox(width: 14),
            SizedBox(
                width: 34,
                child: Text(
                  '${workouts.where((item) => item.category == category).length} 天',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                  textAlign: TextAlign.end,
                )),
          ]),
        ),
      const SizedBox(height: 4),
      Container(
        key: const Key('indulgence-overview'),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: TrainingCategory.indulgence.tint,
            borderRadius: BorderRadius.circular(12)),
        child: Text('放纵日 $indulgenceDays 天 · 不计入训练统计',
            style: const TextStyle(fontSize: 11, color: AppColors.ink)),
      ),
      const SizedBox(height: 12),
      const Divider(height: 1),
      const SizedBox(height: 24),
      const Text('本月记录',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      if (sorted.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 38),
          child: Center(
              child: Column(children: [
            Icon(Icons.spa_outlined, size: 29, color: Color(0xFF9DAE8D)),
            SizedBox(height: 14),
            Text('属于你的进步，从第一条记录开始。',
                style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ])),
        ),
      for (final workout in sorted)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Material(
            color: const Color(0xFFF8F9F3),
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              onTap: () => onDayTap(workout.date),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              leading: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: workout.category.tint,
                    borderRadius: BorderRadius.circular(10)),
                child: Text(workout.category.label,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w600)),
              ),
              title: Text(friendlyDate(workout.date),
                  style: const TextStyle(fontSize: 12)),
              subtitle: Text(
                  workout.isTraining
                      ? workout.summary
                      : '放纵日 · ${workout.summary}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: AppColors.muted)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.muted),
            ),
          ),
        ),
      if (sorted.any((workout) => workout.totalVolume > 0)) ...[
        const SizedBox(height: 20),
        Text(
            '本月总训练容量 ${formatVolume(sorted.fold(0.0, (sum, item) => sum + item.totalVolume))} kg',
            style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ],
    ]));
  }
}
