import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pullpush/data/workout_repository.dart';
import 'package:pullpush/main.dart';
import 'package:pullpush/models/workout.dart';

class MemoryRepository implements WorkoutRepository {
  Map<String, Workout> records = {};
  bool failLoad = false;
  bool failSave = false;

  @override
  Future<Map<String, Workout>> load() async {
    if (failLoad) throw StateError('Cannot read');
    return {...records};
  }

  @override
  Future<void> save(Map<String, Workout> workouts) async {
    if (failSave) throw StateError('Cannot write');
    records = {...workouts};
  }
}

Future<void> launch(WidgetTester tester, MemoryRepository repository,
    {Size size = const Size(1440, 1200)}) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  await tester.pumpWidget(PullPushApp(
      repository: repository, clock: () => DateTime(2026, 11, 12, 12)));
  await tester.pumpAndSettle();
}

Future<void> finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpAndSettle();
  await tester.binding.setSurfaceSize(null);
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

Future<void> selectExercise(WidgetTester tester, int row,
    TrainingCategory category, String exerciseId) async {
  final selector = find.byKey(Key('exercise-selector-$row'));
  await tester.ensureVisible(selector);
  await tester.tap(selector);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key('picker-category-${category.name}')));
  await tester.pumpAndSettle();
  final option = find.byKey(Key('picker-exercise-$exerciseId'));
  await tester.scrollUntilVisible(option, 120,
      scrollable: find.descendant(
          of: find.byKey(const Key('exercise-options-list')),
          matching: find.byType(Scrollable)));
  await tester.tap(option);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('PullPush name is consistent in the app and platform metadata',
      (tester) async {
    await launch(tester, MemoryRepository(), size: const Size(320, 844));
    expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).title, 'PullPush');
    expect(find.text('PullPush'), findsOneWidget);
    expect(find.text('练记'), findsNothing);
    expect(tester.takeException(), isNull);
    expect(File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
        contains('android:label="PullPush"'));
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    for (final key in ['CFBundleDisplayName', 'CFBundleName']) {
      expect(plist, matches('<key>$key</key>\\s*<string>PullPush</string>'));
    }
    final manifest = jsonDecode(File('web/manifest.json').readAsStringSync());
    expect(manifest['name'], 'PullPush');
    expect(manifest['short_name'], 'PullPush');
    final html = File('web/index.html').readAsStringSync();
    expect(html, contains('<title>PullPush</title>'));
    expect(
        html, contains('name="apple-mobile-web-app-title" content="PullPush"'));
    await finish(tester);
  });

  testWidgets('cascader selects body part then a canonical exercise on mobile',
      (tester) async {
    final repository = MemoryRepository();
    await launch(tester, repository, size: const Size(390, 844));
    await tester.tap(find.byKey(const Key('mobile-add-workout')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('category-abs')));
    await tester.ensureVisible(find.byKey(const Key('add-exercise')));
    await tester.tap(find.byKey(const Key('add-exercise')));
    await tester.pumpAndSettle();
    await selectExercise(tester, 0, TrainingCategory.abs, 'abs_cable_crunch');
    expect(find.text('腹 / 龙门架卷腹'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('exercise-sets-0')));
    await tester.enterText(find.byKey(const Key('exercise-sets-0')), '3');
    await tester.enterText(find.byKey(const Key('exercise-reps-0')), '12');
    await tester.ensureVisible(find.byKey(const Key('exercise-weight-0')));
    await tester.enterText(find.byKey(const Key('exercise-weight-0')), '20');
    await tester.tap(find.byKey(const Key('save-workout')));
    await tester.pumpAndSettle();
    final workout = repository.records.values.single;
    expect(workout.category, TrainingCategory.abs);
    expect(workout.exercises.single.name, '龙门架卷腹');
    expect(workout.exercises.single.catalogId, 'abs_cable_crunch');
    expect(workout.exercises.single.weightMode, WeightMode.standard);
    expect(workout.totalVolume, 720);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('drop weights require two descending values and survive editing',
      (tester) async {
    final repository = MemoryRepository();
    await launch(tester, repository, size: const Size(390, 844));
    await tester.tap(find.byKey(const Key('mobile-add-workout')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('add-exercise')));
    await tester.tap(find.byKey(const Key('add-exercise')));
    await tester.pumpAndSettle();
    await selectExercise(
        tester, 0, TrainingCategory.chest, 'chest_barbell_bench_press');
    await tester.ensureVisible(find.byKey(const Key('weight-drop-0')));
    await tester.tap(find.byKey(const Key('weight-drop-0')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('exercise-sets-0')));
    await tester.enterText(find.byKey(const Key('exercise-sets-0')), '3');
    await tester.enterText(find.byKey(const Key('exercise-reps-0')), '10');
    await tester
        .ensureVisible(find.byKey(const Key('exercise-drop-weight-0-0')));
    await tester.enterText(
        find.byKey(const Key('exercise-drop-weight-0-0')), '60');
    await tester.tap(find.byKey(const Key('save-workout')));
    await tester.pumpAndSettle();
    expect(find.text('请填写重量'), findsOneWidget);
    expect(repository.records, isEmpty);
    await tester
        .ensureVisible(find.byKey(const Key('exercise-drop-weight-0-1')));
    await tester.enterText(
        find.byKey(const Key('exercise-drop-weight-0-1')), '60');
    await tester.tap(find.byKey(const Key('save-workout')));
    await tester.pumpAndSettle();
    expect(find.text('需小于上一级重量'), findsOneWidget);
    expect(repository.records, isEmpty);
    await tester
        .ensureVisible(find.byKey(const Key('exercise-drop-weight-0-1')));
    await tester.enterText(
        find.byKey(const Key('exercise-drop-weight-0-1')), '40');
    await tester.ensureVisible(find.byKey(const Key('add-drop-weight-0')));
    await tester.tap(find.byKey(const Key('add-drop-weight-0')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('exercise-drop-weight-0-2')));
    await tester.enterText(
        find.byKey(const Key('exercise-drop-weight-0-2')), '20');
    await tester.tap(find.byKey(const Key('save-workout')));
    await tester.pumpAndSettle();
    final exercise = repository.records.values.single.exercises.single;
    expect(exercise.weightMode, WeightMode.dropSet);
    expect(exercise.dropWeights, [60, 40, 20]);
    expect(exercise.volume, 3600);
    await tester.ensureVisible(find.byKey(const Key('day-2026-11-12')));
    await tester.tap(find.byKey(const Key('day-2026-11-12')));
    await tester.pumpAndSettle();
    expect(find.textContaining('60 → 40 → 20 kg'), findsOneWidget);
    expect(find.textContaining('每级 10 次'), findsOneWidget);
    await tester.tap(find.byKey(const Key('edit-workout')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextFormField>(
                find.byKey(const Key('exercise-drop-weight-0-2')))
            .controller!
            .text,
        '20');
    await tester.tap(find.byKey(const Key('save-workout')));
    await tester.pumpAndSettle();
    expect(repository.records.values.single.exercises.single.dropWeights,
        [60, 40, 20]);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('detail shows exact decimal weights without rounding stages',
      (tester) async {
    final repository = MemoryRepository();
    final workout = Workout(
        date: DateTime(2026, 11, 12),
        category: TrainingCategory.chest,
        exercises: [
          Exercise(name: '杠铃卧推', sets: 3, weight: 12.25),
          Exercise(
              name: '哑铃上斜卧推',
              sets: 3,
              weightMode: WeightMode.dropSet,
              dropWeights: [20.25, 10.25, 0]),
        ]);
    repository.records[workout.key] = workout;
    await launch(tester, repository);
    await tester.tap(find.byKey(const Key('day-2026-11-12')));
    await tester.pumpAndSettle();
    expect(find.textContaining('标准重量 12.25 kg'), findsOneWidget);
    expect(find.textContaining('20.25 → 10.25 → 0 kg'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('complete create, read, edit, cancel-delete and delete flow',
      (tester) async {
    final repository = MemoryRepository();
    await launch(tester, repository);
    expect(find.text('把坚持，记在这里。'), findsOneWidget);
    expect(repository.records, isEmpty);

    await tester.tap(find.byKey(const Key('day-2026-11-12')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('category-shoulder')));
    await tester.enterText(
        find.byKey(const Key('note-input')), '推举状态不错，注意控制下放。');
    await tester.ensureVisible(find.byKey(const Key('add-exercise')));
    await tester.tap(find.byKey(const Key('add-exercise')));
    await tester.pumpAndSettle();
    await selectExercise(
        tester, 0, TrainingCategory.shoulder, 'shoulder_seated_dumbbell_press');
    await tester.ensureVisible(find.byKey(const Key('exercise-sets-0')));
    await tester.enterText(find.byKey(const Key('exercise-sets-0')), '4');
    await tester.enterText(find.byKey(const Key('exercise-reps-0')), '10');
    await tester.enterText(find.byKey(const Key('exercise-weight-0')), '12.5');
    await tester.tap(find.byKey(const Key('save-workout')));
    await tester.pumpAndSettle();
    expect(repository.records.length, 1);
    expect(
        repository.records.values.single.category, TrainingCategory.shoulder);
    expect(repository.records.values.single.totalVolume, 500);
    expect(find.byKey(const Key('save-workout')), findsNothing);

    await tester.tap(find.byKey(const Key('day-2026-11-12')));
    await tester.pumpAndSettle();
    expect(find.text('推举状态不错，注意控制下放。'), findsOneWidget);
    expect(find.text('坐姿哑铃推肩'), findsOneWidget);
    await tester.tap(find.byKey(const Key('edit-workout')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('category-back')));
    await tester.enterText(find.byKey(const Key('note-input')), '改成背部训练');
    await tester.tap(find.byKey(const Key('save-workout')));
    await tester.pumpAndSettle();
    expect(repository.records.values.single.category, TrainingCategory.back);
    expect(repository.records.values.single.note, '改成背部训练');

    await tester.tap(find.byKey(const Key('day-2026-11-12')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-workout')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('再想想'));
    await tester.pumpAndSettle();
    expect(repository.records.length, 1);
    await tester.tap(find.byKey(const Key('day-2026-11-12')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-workout')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete')));
    await tester.pumpAndSettle();
    expect(repository.records, isEmpty);
    await finish(tester);
  });

  testWidgets('notes-only training works and failed saves keep the draft',
      (tester) async {
    final repository = MemoryRepository()..failSave = true;
    await launch(tester, repository);
    await tester.tap(find.byKey(const Key('day-2026-11-12')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('note-input')), '深蹲 5 组，80 kg');
    await tester.tap(find.byKey(const Key('save-workout')));
    await tester.pumpAndSettle();
    expect(find.text('保存失败，内容仍在。请检查设备存储空间后重试。'), findsOneWidget);
    expect(repository.records, isEmpty);
    expect(find.byKey(const Key('save-workout')), findsOneWidget);
    repository.failSave = false;
    await tester.tap(find.byKey(const Key('save-workout')));
    await tester.pumpAndSettle();
    expect(repository.records.values.single.note, '深蹲 5 组，80 kg');
    expect(repository.records.values.single.exercises, isEmpty);
    await finish(tester);
  });

  testWidgets('read failures disable edits and can be retried safely',
      (tester) async {
    final repository = MemoryRepository()..failLoad = true;
    await launch(tester, repository);
    expect(find.text('暂时无法读取本机记录'), findsOneWidget);
    final button =
        tester.widget<FilledButton>(find.byKey(const Key('add-workout')));
    expect(button.onPressed, isNull);
    repository.failLoad = false;
    await tester.tap(find.text('重新读取'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('day-2026-11-12')), findsOneWidget);
    await finish(tester);
  });

  testWidgets('month navigation crosses years and review displays actual data',
      (tester) async {
    final repository = MemoryRepository();
    final workout = Workout(
        date: DateTime(2026, 11, 2),
        category: TrainingCategory.arms,
        note: '弯举');
    repository.records[workout.key] = workout;
    await launch(tester, repository);
    await tester.tap(find.byKey(const Key('next-month')));
    await tester.pumpAndSettle();
    expect(find.text('DECEMBER'), findsOneWidget);
    await tester.tap(find.byKey(const Key('next-month')));
    await tester.pumpAndSettle();
    expect(find.text('JANUARY'), findsOneWidget);
    expect(find.text('2027'), findsOneWidget);
    await tester.tap(find.text('今天').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-overview')));
    await tester.pumpAndSettle();
    expect(find.text('YOUR TRAINING BALANCE'), findsOneWidget);
    expect(find.text('弯举'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('discard confirmation protects unsaved notes', (tester) async {
    final repository = MemoryRepository();
    await launch(tester, repository);
    await tester.tap(find.byKey(const Key('day-2026-11-12')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('note-input')), '还没有保存的训练');
    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('放弃这次修改？'), findsOneWidget);
    await tester.tap(find.text('继续填写'));
    await tester.pumpAndSettle();
    expect(find.text('还没有保存的训练'), findsOneWidget);
    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('放弃修改'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('save-workout')), findsNothing);
    expect(repository.records, isEmpty);
    await finish(tester);
  });

  testWidgets('invalid exercises cannot save, and zero kg is valid',
      (tester) async {
    final repository = MemoryRepository();
    await launch(tester, repository);
    await tester.tap(find.byKey(const Key('day-2026-11-12')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('add-exercise')));
    await tester.tap(find.byKey(const Key('add-exercise')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('exercise-sets-0')), '0');
    await tester.tap(find.byKey(const Key('save-workout')));
    await tester.pumpAndSettle();
    expect(find.text('请选择训练动作'), findsOneWidget);
    expect(find.text('数值无效'), findsOneWidget);
    expect(repository.records, isEmpty);
    await selectExercise(tester, 0, TrainingCategory.back, 'back_pull_up');
    await tester.ensureVisible(find.byKey(const Key('exercise-sets-0')));
    await tester.enterText(find.byKey(const Key('exercise-sets-0')), '3');
    await tester.enterText(find.byKey(const Key('exercise-reps-0')), '12');
    await tester.enterText(find.byKey(const Key('exercise-weight-0')), '0');
    await tester.tap(find.byKey(const Key('save-workout')));
    await tester.pumpAndSettle();
    expect(repository.records.values.single.exercises.single.weight, 0);
    expect(repository.records.values.single.totalSets, 3);
    await finish(tester);
  });

  testWidgets('mobile editor keeps save accessible above the keyboard',
      (tester) async {
    final repository = MemoryRepository();
    await launch(tester, repository, size: const Size(390, 844));
    await tester.ensureVisible(find.byKey(const Key('day-2026-11-12')));
    await tester.tap(find.byKey(const Key('day-2026-11-12')));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const Key('note-input')));
    await tester.enterText(find.byKey(const Key('note-input')), '键盘上方也可以保存');
    await tester.tap(find.byKey(const Key('save-workout')));
    await tester.pumpAndSettle();
    expect(repository.records.values.single.note, '键盘上方也可以保存');
    tester.view.resetViewInsets();
    await finish(tester);
  });

  testWidgets('indulgence days have a notes-only create, read and delete flow',
      (tester) async {
    final repository = MemoryRepository();
    await launch(tester, repository, size: const Size(390, 844));
    await tester.tap(find.byKey(const Key('mobile-add-workout')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('category-indulgence')));
    await tester.pumpAndSettle();
    expect(find.text('记下这个放纵日'), findsOneWidget);
    expect(find.text('放纵日备注'), findsOneWidget);
    expect(find.byKey(const Key('add-exercise')), findsNothing);
    expect(find.text('保存放纵日'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('note-input')));
    await tester.enterText(find.byKey(const Key('note-input')), '今天吃火锅');
    await tester.tap(find.byKey(const Key('save-workout')));
    await tester.pumpAndSettle();
    expect(
        repository.records.values.single.category, TrainingCategory.indulgence);
    expect(repository.records.values.single.exercises, isEmpty);
    expect(repository.records.values.single.note, '今天吃火锅');
    expect(
        find.descendant(
            of: find.byKey(const Key('stat-本月训练')), matching: find.text('00')),
        findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('day-2026-11-12')));
    await tester.tap(find.byKey(const Key('day-2026-11-12')));
    await tester.pumpAndSettle();
    expect(find.text('放纵日已记录'), findsOneWidget);
    expect(find.text('训练已记录'), findsNothing);
    expect(find.text('今天吃火锅'), findsAtLeastNWidgets(1));
    await tester.tap(find.byKey(const Key('delete-workout')));
    await tester.pumpAndSettle();
    expect(find.text('删除这个放纵日？'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-delete')));
    await tester.pumpAndSettle();
    expect(repository.records, isEmpty);
    await finish(tester);
  });

  testWidgets('switching to indulgence ignores hidden exercise validation',
      (tester) async {
    final repository = MemoryRepository();
    await launch(tester, repository);
    await tester.tap(find.byKey(const Key('day-2026-11-12')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('add-exercise')));
    await tester.tap(find.byKey(const Key('add-exercise')));
    await tester.pumpAndSettle();
    await selectExercise(
        tester, 0, TrainingCategory.chest, 'chest_barbell_bench_press');
    await tester.ensureVisible(find.byKey(const Key('exercise-sets-0')));
    await tester.enterText(find.byKey(const Key('exercise-sets-0')), '0');
    await tester.ensureVisible(find.byKey(const Key('category-indulgence')));
    await tester.tap(find.byKey(const Key('category-indulgence')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('exercise-selector-0')), findsNothing);
    await tester.tap(find.byKey(const Key('category-chest')));
    await tester.pumpAndSettle();
    expect(find.text('胸 / 杠铃卧推'), findsOneWidget);
    await tester.tap(find.byKey(const Key('category-indulgence')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-workout')));
    await tester.pumpAndSettle();
    expect(repository.records.values.single.isTraining, isFalse);
    expect(repository.records.values.single.exercises, isEmpty);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets(
      'training statistics exclude indulgence and legacy detail survives editing',
      (tester) async {
    final repository = MemoryRepository();
    for (final record in [
      Workout(
          date: DateTime(2026, 11, 11),
          category: TrainingCategory.chest,
          exercises: [
            Exercise(name: '卧推', sets: 4, reps: 10, weight: 60),
          ]),
      Workout(
          date: DateTime(2026, 11, 12),
          category: TrainingCategory.indulgence,
          note: '火锅',
          exercises: [
            Exercise(name: '旧版动作', sets: 99, reps: 10, weight: 70),
          ]),
      Workout(
          date: DateTime(2026, 11, 13), category: TrainingCategory.indulgence),
      Workout(
          date: DateTime(2026, 10, 12),
          category: TrainingCategory.legs,
          exercises: [Exercise(name: '深蹲', sets: 10)]),
    ]) {
      repository.records[record.key] = record;
    }
    await launch(tester, repository);
    expect(
        find.descendant(
            of: find.byKey(const Key('stat-本月训练')), matching: find.text('01')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('stat-累计组数')), matching: find.text('04')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('stat-训练部位')), matching: find.text('01')),
        findsOneWidget);
    expect(find.text('/ 6'), findsOneWidget);
    expect(find.text('1 / 7 天'), findsOneWidget);
    expect(find.text('放纵日 · 已记录'), findsOneWidget);
    await tester.tap(find.byKey(const Key('nav-overview')));
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNWidgets(6));
    expect(find.text('放纵日 2 天 · 不计入训练统计'), findsNWidgets(2));
    expect(find.text('本月总训练容量 2400 kg'), findsOneWidget);
    final chestBar = tester.widget<LinearProgressIndicator>(find.descendant(
        of: find.byKey(const Key('balance-chest')),
        matching: find.byType(LinearProgressIndicator)));
    expect(chestBar.value, 1);
    await tester.tap(find.byKey(const Key('nav-calendar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('day-2026-11-12')));
    await tester.pumpAndSettle();
    expect(find.text('历史动作明细'), findsOneWidget);
    expect(find.text('旧版动作'), findsOneWidget);
    await tester.tap(find.byKey(const Key('edit-workout')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('add-exercise')), findsNothing);
    await tester.enterText(find.byKey(const Key('note-input')), '更新放纵日备注');
    await tester.tap(find.byKey(const Key('save-workout')));
    await tester.pumpAndSettle();
    expect(repository.records['2026-11-12']!.note, '更新放纵日备注');
    expect(repository.records['2026-11-12']!.exercises.single.name, '旧版动作');
    expect(repository.records['2026-11-12']!.totalSets, 0);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets(
        'cascader and drop weights fit ${width.toInt()}px with keyboard',
        (tester) async {
      final repository = MemoryRepository();
      await launch(tester, repository, size: Size(width, 900));
      await tester.ensureVisible(find.byKey(const Key('day-2026-11-12')));
      await tester.tap(find.byKey(const Key('day-2026-11-12')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('add-exercise')));
      await tester.tap(find.byKey(const Key('add-exercise')));
      await tester.pumpAndSettle();
      await selectExercise(
          tester, 0, TrainingCategory.legs, 'legs_hamstring_curl');
      await tester.ensureVisible(find.byKey(const Key('weight-drop-0')));
      await tester.tap(find.byKey(const Key('weight-drop-0')));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      await tester.pumpAndSettle();
      await tester
          .ensureVisible(find.byKey(const Key('exercise-drop-weight-0-0')));
      await tester.enterText(
          find.byKey(const Key('exercise-drop-weight-0-0')), '30.5');
      await tester
          .ensureVisible(find.byKey(const Key('exercise-drop-weight-0-1')));
      await tester.enterText(
          find.byKey(const Key('exercise-drop-weight-0-1')), '20.25');
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('save-workout')));
      await tester.pumpAndSettle();
      expect(repository.records.values.single.exercises.single.dropWeights,
          [30.5, 20.25]);
      tester.view.resetViewInsets();
      await finish(tester);
    });

    testWidgets('calendar and editor fit a ${width.toInt()}px viewport',
        (tester) async {
      final repository = MemoryRepository();
      await launch(tester, repository, size: Size(width, 900));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const Key('day-2026-11-12')));
      await tester.tap(find.byKey(const Key('day-2026-11-12')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byKey(const Key('note-input')), '今天也有进步');
      await tester.tap(find.byKey(const Key('save-workout')));
      await tester.pumpAndSettle();
      expect(repository.records.length, 1);
      expect(tester.takeException(), isNull);
      await finish(tester);
    });
  }
}
