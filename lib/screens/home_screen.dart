import 'dart:async';

import 'package:flutter/material.dart';

import '../data/workout_repository.dart';
import '../models/workout.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/training_overview.dart';
import '../widgets/training_sidebar.dart';
import '../widgets/workout_calendar.dart';
import '../widgets/workout_detail.dart';
import '../widgets/workout_editor.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository, required this.clock});

  final WorkoutRepository repository;
  final DateTime Function() clock;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late DateTime _today;
  late DateTime _month;
  Map<String, Workout> _workouts = {};
  bool _loading = true;
  bool _loadFailed = false;
  bool _overview = false;
  bool _writing = false;
  TrainingCategory? _filter;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _today = dateOnly(widget.clock());
    _month = DateTime(_today.year, _today.month);
    _load();
    _scheduleMidnight();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _today = dateOnly(widget.clock()));
      _scheduleMidnight();
    }
  }

  void _scheduleMidnight() {
    _midnightTimer?.cancel();
    final now = widget.clock();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer =
        Timer(next.difference(now) + const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _today = dateOnly(widget.clock()));
      _scheduleMidnight();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final records = await widget.repository.load();
      if (mounted) {
        setState(() {
          _workouts = records;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadFailed = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _persist(Map<String, Workout> next) async {
    if (_writing) throw StateError('A write is already in progress');
    _writing = true;
    try {
      await widget.repository.save(next);
      if (mounted) setState(() => _workouts = next);
    } finally {
      _writing = false;
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
          SnackBar(content: Text(text), duration: const Duration(seconds: 3)));
  }

  Future<void> _openDay(DateTime date) async {
    if (_loading || _loadFailed || _writing) return;
    final existing = _workouts[dateKey(date)];
    if (existing == null) {
      await _edit(date);
      return;
    }
    final action = await showWorkoutModal<WorkoutAction>(
      context: context,
      builder: (_) => WorkoutDetail(workout: existing),
    );
    if (!mounted) return;
    if (action == WorkoutAction.edit) await _edit(date, existing);
    if (action == WorkoutAction.delete) await _delete(existing);
  }

  Future<void> _edit(DateTime date, [Workout? existing]) async {
    Workout? savedWorkout;
    final saved = await showWorkoutModal<bool>(
      context: context,
      dismissible: false,
      builder: (_) => WorkoutEditor(
        date: date,
        existing: existing,
        onSave: (workout) async {
          await _persist({..._workouts, workout.key: workout});
          savedWorkout = workout;
        },
      ),
    );
    if (saved == true && mounted) {
      setState(() => _month = DateTime(date.year, date.month));
      _toast(savedWorkout!.isTraining ? '已记下，每一次训练都算数。' : '放纵日已记下，享受生活也很重要。');
    }
  }

  Future<void> _delete(Workout workout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text(workout.isTraining ? '删除这次训练？' : '删除这个放纵日？',
            style: const TextStyle(fontSize: 19)),
        content: Text(
            '${friendlyDate(workout.date)}的${workout.isTraining ? '训练' : '放纵日'}记录和备注将被删除，此操作无法撤销。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('再想想')),
          FilledButton(
            key: const Key('confirm-delete'),
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _persist({..._workouts}..remove(workout.key));
      _toast('记录已删除，留点空白也没关系。');
    } catch (_) {
      _toast('删除未成功，原记录仍在。请稍后重试。');
    }
  }

  void _changeMonth(int delta) => setState(() {
        _month = DateTime(_month.year, _month.month + delta);
      });

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
      helpText: '跳转到日期',
      confirmText: '查看月份',
    );
    if (date != null && mounted) {
      setState(() => _month = DateTime(date.year, date.month));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 680;
    final wide = size.width >= 1030;
    final monthlyRecords = _workouts.values
        .where((workout) =>
            workout.date.year == _month.year &&
            workout.date.month == _month.month)
        .toList();
    final trainingRecords =
        monthlyRecords.where((item) => item.isTraining).toList();
    final totalSets =
        trainingRecords.fold(0, (sum, item) => sum + item.totalSets);
    final uniqueCategories =
        trainingRecords.map((item) => item.category).toSet().length;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          _header(compact),
          Expanded(
              child: SingleChildScrollView(
            child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1260),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(compact ? 18 : 40,
                        compact ? 27 : 41, compact ? 18 : 40, 22),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _hero(compact),
                          SizedBox(height: compact ? 25 : 31),
                          _stats(trainingRecords.length, totalSets,
                              uniqueCategories, compact),
                          SizedBox(height: compact ? 21 : 28),
                          if (_loading)
                            const SizedBox(
                                height: 400,
                                child: Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)))
                          else if (_loadFailed)
                            _errorPanel()
                          else
                            Flex(
                              direction: wide ? Axis.horizontal : Axis.vertical,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (wide)
                                  Expanded(child: _mainPanel(monthlyRecords))
                                else
                                  SizedBox(
                                      width: double.infinity,
                                      child: _mainPanel(monthlyRecords)),
                                SizedBox(
                                    width: wide ? 23 : 0,
                                    height: wide ? 0 : 22),
                                SizedBox(
                                    width: wide ? 286 : double.infinity,
                                    child: TrainingSidebar(
                                      today: _today,
                                      month: _month,
                                      workouts: _workouts,
                                      onToday: () => _openDay(_today),
                                      onOverview: () =>
                                          setState(() => _overview = true),
                                    )),
                              ],
                            ),
                          SizedBox(height: compact ? 29 : 35),
                          _footer(compact),
                        ]),
                  ),
                )),
          )),
        ]),
      ),
      floatingActionButton: compact && !_loading && !_loadFailed
          ? FloatingActionButton(
              key: const Key('mobile-add-workout'),
              onPressed: () => _openDay(_today),
              tooltip: '记录今天',
              backgroundColor: AppColors.forest,
              foregroundColor: AppColors.lime,
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.add_rounded, size: 27),
            )
          : null,
    );
  }

  Widget _mainPanel(List<Workout> monthlyRecords) => _overview
      ? TrainingOverview(
          month: _month,
          workouts: monthlyRecords,
          onDayTap: _openDay,
          onMonthChange: _changeMonth)
      : WorkoutCalendar(
          month: _month,
          today: _today,
          workouts: _workouts,
          onDayTap: _openDay,
          onMonthChange: _changeMonth,
          onToday: () => setState(() {
            _month = DateTime(_today.year, _today.month);
            _filter = null;
          }),
          onPickDate: _pickDate,
          filter: _filter,
          onFilter: (category) => setState(() => _filter = category),
        );

  Widget _header(bool compact) => Container(
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.line))),
        child: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1260),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: compact ? 18 : 40, vertical: compact ? 15 : 20),
            child: Row(children: [
              BrandMark(size: compact ? 35 : 40),
              const SizedBox(width: 11),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text('PullPush',
                            style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: compact ? 17 : 23,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                                height: 1.2))),
                    if (!compact) ...[
                      const SizedBox(height: 5),
                      const Text('你的私人训练手账',
                          style: TextStyle(
                              fontSize: 9,
                              color: AppColors.muted,
                              letterSpacing: 1)),
                    ],
                  ])),
              _navButton('训练日历', Icons.calendar_month_outlined, false, compact),
              SizedBox(width: compact ? 3 : 14),
              _navButton('训练回顾', Icons.bar_chart_rounded, true, compact),
              if (!compact) ...[
                const SizedBox(width: 40),
                const Icon(Icons.cloud_off_outlined,
                    size: 15, color: AppColors.muted),
                const SizedBox(width: 7),
                const Text('本地记录 · 无需登录',
                    style: TextStyle(fontSize: 10, color: AppColors.muted)),
              ],
            ]),
          ),
        )),
      );

  Widget _navButton(String title, IconData icon, bool overview, bool compact) {
    final selected = _overview == overview;
    return TextButton.icon(
      key: Key(overview ? 'nav-overview' : 'nav-calendar'),
      onPressed: () => setState(() => _overview = overview),
      style: TextButton.styleFrom(
        foregroundColor: selected ? AppColors.forest : AppColors.muted,
        backgroundColor:
            selected ? const Color(0xFFE9EDDF) : Colors.transparent,
        padding:
            EdgeInsets.symmetric(horizontal: compact ? 10 : 15, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      icon: Icon(icon, size: compact ? 15 : 16),
      label: Text(title,
          style: TextStyle(
              fontSize: compact ? 10 : 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
    );
  }

  Widget _hero(bool compact) =>
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Dot(size: 5, color: Color(0xFF8B9D6C)),
            SizedBox(width: 8),
            Expanded(
                child: Eyebrow('A LITTLE STRONGER, EVERY DAY',
                    color: Color(0xFF7E8C6D))),
          ]),
          SizedBox(height: compact ? 14 : 16),
          Text(_overview ? '每一点进步，都有回响。' : '把坚持，记在这里。',
              style: TextStyle(
                  fontSize: compact ? 29 : 39,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                  letterSpacing: compact ? -.8 : -1.5,
                  height: 1.4)),
          const SizedBox(height: 10),
          const Text('不必每一次都突破。每一次来，都算数。',
              style: TextStyle(
                  fontSize: 12, color: AppColors.muted, letterSpacing: .3)),
        ])),
        if (!compact)
          Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: FilledButton.icon(
                key: const Key('add-workout'),
                onPressed:
                    _loading || _loadFailed ? null : () => _openDay(_today),
                icon: const Icon(Icons.add_rounded, size: 19),
                label: const Text('记下今天'),
              )),
      ]);

  Widget _stats(int days, int sets, int categories, bool compact) => Container(
        padding: EdgeInsets.symmetric(
            vertical: compact ? 15 : 18, horizontal: compact ? 0 : 2),
        decoration: const BoxDecoration(
            border: Border(
          top: BorderSide(color: AppColors.line),
          bottom: BorderSide(color: AppColors.line),
        )),
        child: Row(children: [
          _stat('本月训练', '$days'.padLeft(2, '0'), '天', compact),
          Container(
              height: 31,
              width: 1,
              color: AppColors.line,
              margin: EdgeInsets.symmetric(horizontal: compact ? 16 : 35)),
          _stat('累计组数', '$sets'.padLeft(2, '0'), '组', compact),
          Container(
              height: 31,
              width: 1,
              color: AppColors.line,
              margin: EdgeInsets.symmetric(horizontal: compact ? 16 : 35)),
          _stat('训练部位', '$categories'.padLeft(2, '0'),
              '/ ${TrainingCategory.training.length}', compact),
          if (!compact) ...[
            const Spacer(),
            const Text('慢慢来，也是在向前。',
                style: TextStyle(fontSize: 11, color: AppColors.muted)),
            const SizedBox(width: 11),
            const Icon(Icons.wb_sunny_outlined,
                size: 18, color: Color(0xFF9CA87C)),
          ],
        ]),
      );

  Widget _stat(String title, String value, String unit, bool compact) =>
      ExpandedIf(
        expanded: compact,
        child: Column(
            key: Key('stat-$title'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: compact ? 10 : 11, color: AppColors.muted)),
              const SizedBox(height: 6),
              Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    if (compact)
                      Flexible(
                          child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(value,
                            style: numberStyle(24, weight: FontWeight.w500)),
                      ))
                    else
                      Text(value,
                          style: numberStyle(28, weight: FontWeight.w500)),
                    const SizedBox(width: 7),
                    Text(unit,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.muted)),
                  ]),
            ]),
      );

  Widget _errorPanel() => PaperPanel(
          child: SizedBox(
        width: double.infinity,
        child: Column(children: [
          const Icon(Icons.folder_off_outlined,
              size: 32, color: AppColors.muted),
          const SizedBox(height: 16),
          const Text('暂时无法读取本机记录',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('为保护已有数据，已暂停新增和修改。请重试；不会覆盖原记录。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: _load, child: const Text('重新读取')),
        ]),
      ));

  Widget _footer(bool compact) => Column(children: [
        if (!compact) ...[
          const Center(
              child: Text('「 训练是和自己的约定，而记录，让每一次坚持都有迹可循。 」',
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: .7,
                      color: Color(0xFF939A87)))),
          const SizedBox(height: 31),
        ],
        Row(children: [
          const Dot(size: 5, color: Color(0xFF93A47E)),
          const SizedBox(width: 7),
          const Expanded(
              child: Text('数据仅保存在此设备 · 记得珍惜每一次进步',
                  style: TextStyle(fontSize: 9, color: AppColors.muted))),
          if (!compact)
            const Eyebrow('ONE DAY AT A TIME.', color: Color(0xFF9CA28F)),
        ]),
        if (compact) const SizedBox(height: 50),
      ]);
}

class ExpandedIf extends StatelessWidget {
  const ExpandedIf({super.key, required this.expanded, required this.child});
  final bool expanded;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      expanded ? Expanded(child: child) : child;
}
