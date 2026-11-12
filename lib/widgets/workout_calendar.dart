import 'package:flutter/material.dart';

import '../models/workout.dart';
import '../theme.dart';
import 'common.dart';

class WorkoutCalendar extends StatelessWidget {
  const WorkoutCalendar({
    super.key,
    required this.month,
    required this.today,
    required this.workouts,
    required this.onDayTap,
    required this.onMonthChange,
    required this.onToday,
    required this.onPickDate,
    this.filter,
    required this.onFilter,
  });

  final DateTime month;
  final DateTime today;
  final Map<String, Workout> workouts;
  final ValueChanged<DateTime> onDayTap;
  final ValueChanged<int> onMonthChange;
  final VoidCallback onToday;
  final VoidCallback onPickDate;
  final TrainingCategory? filter;
  final ValueChanged<TrainingCategory?> onFilter;

  static const monthNames = [
    'JANUARY',
    'FEBRUARY',
    'MARCH',
    'APRIL',
    'MAY',
    'JUNE',
    'JULY',
    'AUGUST',
    'SEPTEMBER',
    'OCTOBER',
    'NOVEMBER',
    'DECEMBER',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 520;
      final padding = compact ? 12.0 : 24.0;
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final cellHeight = (compact ? 82.0 : 106.0) * textScale.clamp(1, 1.8);
      final days = calendarDays(month);
      return PaperPanel(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  EdgeInsets.fromLTRB(compact ? 2 : 4, 2, 0, compact ? 15 : 22),
              child: Row(
                children: [
                  Expanded(
                      child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Semantics(
                            button: true,
                            label: '选择月份，当前 ${month.year} 年 ${month.month} 月',
                            child: InkWell(
                              onTap: onPickDate,
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(month.month.toString().padLeft(2, '0'),
                                        style: numberStyle(compact ? 29 : 34)),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('${month.year}',
                                            style: numberStyle(12,
                                                color: AppColors.muted)),
                                        const SizedBox(height: 3),
                                        Text(monthNames[month.month - 1],
                                            style: const TextStyle(
                                              fontFamily: 'Manrope',
                                              fontSize: 8,
                                              letterSpacing: 1.4,
                                              color: AppColors.muted,
                                            )),
                                      ],
                                    ),
                                    const SizedBox(width: 3),
                                    const Icon(Icons.expand_more_rounded,
                                        size: 16, color: AppColors.muted),
                                  ],
                                ),
                              ),
                            ),
                          ))),
                  IconButton(
                    key: const Key('previous-month'),
                    onPressed: month.year > 1900 || month.month > 1
                        ? () => onMonthChange(-1)
                        : null,
                    tooltip: '上个月',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.chevron_left_rounded, size: 21),
                  ),
                  TextButton(
                    onPressed: onToday,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      minimumSize: const Size(44, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                    ),
                    child: const Text('今天', style: TextStyle(fontSize: 11)),
                  ),
                  IconButton(
                    key: const Key('next-month'),
                    onPressed: month.year < 2100 || month.month < 12
                        ? () => onMonthChange(1)
                        : null,
                    tooltip: '下个月',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.chevron_right_rounded, size: 21),
                  ),
                  if (!compact) ...[
                    Container(
                        height: 20,
                        width: 1,
                        color: AppColors.line,
                        margin: const EdgeInsets.symmetric(horizontal: 12)),
                    _filterMenu(),
                  ],
                ],
              ),
            ),
            Row(
              children: [
                for (final day in ['一', '二', '三', '四', '五', '六', '日'])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Center(
                          child: Text(day,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ))),
                    ),
                  ),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            for (var week = 0; week < days.length ~/ 7; week++)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    for (var weekday = 0; weekday < 7; weekday++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: compact ? 1.5 : 3),
                          child: _DayCell(
                            date: days[week * 7 + weekday],
                            inMonth:
                                days[week * 7 + weekday].month == month.month,
                            today: today,
                            workout:
                                workouts[dateKey(days[week * 7 + weekday])],
                            filter: filter,
                            height: cellHeight,
                            compact: compact,
                            onTap: () => onDayTap(days[week * 7 + weekday]),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.only(top: 14, left: 3, right: 3),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Dot(size: 5),
                    const SizedBox(width: 6),
                    const Text('今天',
                        style: TextStyle(fontSize: 10, color: AppColors.muted)),
                    const SizedBox(width: 17),
                    Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: TrainingCategory.chest.tint,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: const Color(0xFFD7DDBF)),
                        )),
                    const SizedBox(width: 6),
                    const Text('已记录',
                        style: TextStyle(fontSize: 10, color: AppColors.muted)),
                    if (compact) ...[const SizedBox(width: 10), _filterMenu()],
                  ]),
                  if (!compact)
                    const Text('点击日期，留下一点进步  ↗',
                        style: TextStyle(fontSize: 10, color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _filterMenu() => PopupMenuButton<String>(
        tooltip: '筛选记录类型',
        initialValue: filter?.name ?? 'all',
        onSelected: (value) => onFilter(
            value == 'all' ? null : TrainingCategory.values.byName(value)),
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'all', child: Text('全部记录')),
          for (final category in TrainingCategory.values)
            PopupMenuItem(
                value: category.name, child: Text(category.displayName)),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(filter == null ? '全部记录' : filter!.displayName,
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            const SizedBox(width: 5),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 15, color: AppColors.muted),
          ]),
        ),
      );
}

class _DayCell extends StatefulWidget {
  const _DayCell({
    required this.date,
    required this.inMonth,
    required this.today,
    required this.workout,
    required this.filter,
    required this.height,
    required this.compact,
    required this.onTap,
  });

  final DateTime date;
  final bool inMonth;
  final DateTime today;
  final Workout? workout;
  final TrainingCategory? filter;
  final double height;
  final bool compact;
  final VoidCallback onTap;

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final isToday = sameDay(widget.date, widget.today);
    final workout = widget.workout;
    final dimmed = widget.filter != null && workout?.category != widget.filter;
    final background = workout?.category.tint ??
        (isToday
            ? const Color(0xFFF1F5E7)
            : (hovered ? AppColors.pale : Colors.transparent));
    final label = '${widget.date.year} 年 ${friendlyDate(widget.date)}，'
        '${workout == null ? '添加记录' : '${workout.category.displayName}，${workout.summary}，查看记录'}';
    return Semantics(
      label: label,
      button: true,
      excludeSemantics: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => hovered = true),
        onExit: (_) => setState(() => hovered = false),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: dimmed ? .3 : (widget.inMonth ? 1 : .4),
          child: Material(
            color: background,
            borderRadius: BorderRadius.circular(widget.compact ? 9 : 12),
            child: InkWell(
              key: Key('day-${dateKey(widget.date)}'),
              onTap: widget.date.year >= 1900 && widget.date.year <= 2100
                  ? widget.onTap
                  : null,
              borderRadius: BorderRadius.circular(widget.compact ? 9 : 12),
              child: Container(
                height: widget.height,
                padding: EdgeInsets.all(widget.compact ? 5 : 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.compact ? 9 : 12),
                  border: Border.all(
                    color:
                        isToday ? const Color(0xFFBDCCA1) : Colors.transparent,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                          child: Text('${widget.date.day}',
                              maxLines: 1,
                              style: numberStyle(
                                11,
                                color: isToday
                                    ? AppColors.forest
                                    : AppColors.muted,
                                weight:
                                    isToday ? FontWeight.w800 : FontWeight.w500,
                              ))),
                      if (isToday) ...[
                        const SizedBox(width: 4),
                        const Dot(size: 4),
                      ],
                    ]),
                    Expanded(
                      child: Center(
                        child: workout != null
                            ? Text(workout.category.label,
                                style: TextStyle(
                                  fontSize: widget.compact ? 25 : 35,
                                  fontWeight: FontWeight.w600,
                                  height: 1.1,
                                  color: AppColors.ink,
                                ))
                            : (isToday || hovered)
                                ? Icon(Icons.add_rounded,
                                    size: widget.compact ? 19 : 23,
                                    color: isToday
                                        ? AppColors.forest
                                        : const Color(0xFFC3CBBB))
                                : const SizedBox.shrink(),
                      ),
                    ),
                    if (!widget.compact)
                      SizedBox(
                        height: 15,
                        child: Center(
                          child: Text(
                            workout?.summary ?? (isToday ? '从今天开始' : ''),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 8, color: AppColors.muted),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
