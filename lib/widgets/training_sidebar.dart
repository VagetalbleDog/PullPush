import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/workout.dart';
import '../theme.dart';
import 'common.dart';

class TrainingSidebar extends StatelessWidget {
  const TrainingSidebar({
    super.key,
    required this.today,
    required this.month,
    required this.workouts,
    required this.onToday,
    required this.onOverview,
  });

  final DateTime today;
  final DateTime month;
  final Map<String, Workout> workouts;
  final VoidCallback onToday;
  final VoidCallback onOverview;

  @override
  Widget build(BuildContext context) {
    final todayWorkout = workouts[dateKey(today)];
    final monthlyWorkouts = workouts.values
        .where((item) =>
            item.date.year == month.year && item.date.month == month.month)
        .toList();
    final trainingDays =
        monthlyWorkouts.where((item) => item.isTraining).length;
    final indulgenceDays = monthlyWorkouts.length - trainingDays;
    final firstOfWeek =
        DateTime(today.year, today.month, today.day - today.weekday + 1);
    final thisWeek = List.generate(
        7,
        (i) =>
            DateTime(firstOfWeek.year, firstOfWeek.month, firstOfWeek.day + i));
    final weekCount = thisWeek
        .where((date) => workouts[dateKey(date)]?.isTraining ?? false)
        .length;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            color: AppColors.forest, borderRadius: BorderRadius.circular(20)),
        child: Stack(children: [
          Positioned(
              right: -34,
              top: -34,
              child: IgnorePointer(
                child: CustomPaint(
                    size: const Size(190, 190), painter: _OrbitPainter()),
              )),
          Padding(
            padding: const EdgeInsets.all(25),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Dot(color: AppColors.lime, size: 5),
                SizedBox(width: 8),
                Expanded(
                    child: Eyebrow('TODAY IS A GOOD DAY',
                        color: Color(0xFFBFCDB9))),
              ]),
              const SizedBox(height: 26),
              Text(
                  todayWorkout == null
                      ? '今天，\n也为自己加一组。'
                      : todayWorkout.isTraining
                          ? '今天，\n你又向前了一步。'
                          : '今天，\n给自己一点自由。',
                  style: const TextStyle(
                      fontSize: 24,
                      height: 1.65,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFFFFEF4),
                      letterSpacing: .5)),
              const SizedBox(height: 13),
              Text(friendlyDate(today),
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFFBFCDB9))),
              const SizedBox(height: 27),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFF4B6954)))),
                child: Row(children: [
                  Icon(
                      todayWorkout == null
                          ? Icons.self_improvement_rounded
                          : todayWorkout.isTraining
                              ? Icons.task_alt_rounded
                              : Icons.wb_sunny_outlined,
                      size: 17,
                      color: AppColors.lime),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          todayWorkout == null
                              ? '准备好，就开始。'
                              : '${todayWorkout.category.displayName} · 已记录',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFFDEE5D4)))),
                ]),
              ),
              const SizedBox(height: 3),
              SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onToday,
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.lime,
                        foregroundColor: AppColors.forest,
                        minimumSize: const Size(0, 46)),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                              todayWorkout == null
                                  ? Icons.add_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 17),
                          const SizedBox(width: 8),
                          Text(todayWorkout == null ? '记下今天' : '查看今日记录',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ]),
                  )),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 18),
      PaperPanel(
        padding: const EdgeInsets.all(23),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(
                child: Text('这个月的足迹',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            IconButton(
                onPressed: onOverview,
                tooltip: '查看训练回顾',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.north_east_rounded,
                    size: 17, color: AppColors.muted)),
          ]),
          const SizedBox(height: 17),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$trainingDays'.padLeft(2, '0'),
                style: numberStyle(45, weight: FontWeight.w500)),
            const Padding(
                padding: EdgeInsets.only(left: 9, bottom: 5),
                child: Text('天训练',
                    style: TextStyle(fontSize: 11, color: AppColors.muted))),
            const Spacer(),
            Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('${month.month} 月',
                    style:
                        const TextStyle(fontSize: 10, color: AppColors.muted))),
          ]),
          const SizedBox(height: 18),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final category in TrainingCategory.training)
              Tooltip(
                message:
                    '${category.displayName} ${monthlyWorkouts.where((w) => w.category == category).length} 天',
                child: Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: category.tint,
                      borderRadius: BorderRadius.circular(7)),
                  child: Text(category.label,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              monthlyWorkouts.any((w) => w.category == category)
                                  ? AppColors.ink
                                  : AppColors.muted)),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          Text('放纵日 $indulgenceDays 天 · 不计入训练统计',
              style: const TextStyle(fontSize: 10, color: AppColors.muted)),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(height: 1)),
          Row(children: [
            const Text('本周节奏',
                style: TextStyle(fontSize: 11, color: AppColors.muted)),
            const Spacer(),
            Text('$weekCount / 7 天',
                style: numberStyle(11, color: AppColors.muted)),
          ]),
          const SizedBox(height: 15),
          Row(children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                  child: Column(children: [
                Container(
                  width: 23,
                  height: 23,
                  decoration: BoxDecoration(
                    color: (workouts[dateKey(thisWeek[i])]?.isTraining ?? false)
                        ? AppColors.forest
                        : workouts.containsKey(dateKey(thisWeek[i]))
                            ? TrainingCategory.indulgence.tint
                            : AppColors.pale,
                    shape: BoxShape.circle,
                    border: sameDay(thisWeek[i], today)
                        ? Border.all(color: const Color(0xFFAABD92))
                        : null,
                  ),
                  child: (workouts[dateKey(thisWeek[i])]?.isTraining ?? false)
                      ? const Icon(Icons.check_rounded,
                          size: 13, color: AppColors.lime)
                      : workouts.containsKey(dateKey(thisWeek[i]))
                          ? const Center(
                              child: Text('纵',
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.ink)))
                          : null,
                ),
                const SizedBox(height: 6),
                Text(['一', '二', '三', '四', '五', '六', '日'][i],
                    style:
                        const TextStyle(fontSize: 9, color: AppColors.muted)),
              ])),
          ]),
        ]),
      ),
      const SizedBox(height: 21),
      const Center(
          child:
              Eyebrow('PROGRESS, NOT PERFECTION.', color: Color(0xFF9B9F90))),
    ]);
  }
}

class _OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF58764B).withValues(alpha: .34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;
    final center = Offset(size.width * .6, size.height * .36);
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(center, 38 + i * 15, paint);
    }
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 4);
    final bar = Paint()..color = const Color(0xFF809363).withValues(alpha: .5);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-27, -2, 54, 4), const Radius.circular(2)),
        bar);
    for (final x in [-22.0, 15.0]) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, -13, 7, 26), const Radius.circular(2)),
          bar);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
