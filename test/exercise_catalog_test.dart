import 'package:flutter_test/flutter_test.dart';
import 'package:pullpush/models/training_catalog.dart';
import 'package:pullpush/models/workout.dart' show Exercise;

void main() {
  test('catalog contains the requested 35 exercises with unique stable IDs',
      () {
    final expected = {
      TrainingCategory.chest: [
        '杠铃卧推',
        '哑铃上斜卧推',
        '固定器械推胸',
        '绳索夹下胸',
        '器械推上胸',
        '器械推下胸',
        '蝴蝶机夹胸',
        '史密斯平板卧推',
        '史密斯上斜卧推',
        '双杠臂屈伸',
      ],
      TrainingCategory.back: [
        '引体向上',
        '辅助引体向上',
        '宽距正握高位下拉',
        '宽距对握高位下拉',
        '窄距对握高位下拉',
        '坐姿窄距划船',
        '大剪刀',
      ],
      TrainingCategory.shoulder: [
        '坐姿哑铃推肩',
        '坐姿史密斯推肩',
        '绳索Y字侧平举',
        '绳索面拉',
        '站姿飞鸟',
        '蝴蝶机反向飞鸟',
      ],
      TrainingCategory.legs: [
        '保加利亚深蹲',
        '史密斯杠铃深蹲',
        '倒蹬',
        '器械内收',
        '器械外展',
        '器械腿弯举—股四',
        '器械腿弯举—腘绳肌',
      ],
      TrainingCategory.arms: ['绳索下拉', '二头弯举'],
      TrainingCategory.abs: ['悬垂举腿', '负重卷腹', '龙门架卷腹'],
    };
    expect(ExerciseCatalog.all, hasLength(35));
    expect(ExerciseCatalog.all.map((item) => item.id).toSet(), hasLength(35));
    for (final entry in expected.entries) {
      expect(ExerciseCatalog.forCategory(entry.key).map((item) => item.name),
          entry.value);
    }
    expect(ExerciseCatalog.forCategory(TrainingCategory.indulgence), isEmpty);
    final bench = ExerciseCatalog.findByName('杠铃卧推')!;
    expect(bench.id, 'chest_barbell_bench_press');
    expect(ExerciseCatalog.findById(bench.id), same(bench));
    expect(ExerciseCatalog.findByName('历史自定义动作'), isNull);
    expect(TrainingCategory.training, hasLength(6));
    expect(TrainingCategory.abs.displayName, '腹部训练');
  });

  test('catalog identity is stable while unmatched historical names are kept',
      () {
    final known = Exercise.fromJson({
      'name': '杠铃卧推',
      'sets': 4,
      'reps': 10,
      'weight': 60,
    });
    expect(known.catalogId, 'chest_barbell_bench_press');
    expect(known.definition!.category, TrainingCategory.chest);
    expect(known.toJson()['catalogId'], known.catalogId);
    expect(Exercise.fromJson(known.toJson()).catalogId, known.catalogId);
    final legacy = Exercise.fromJson({
      'name': '原有自定义动作',
      'sets': 3,
      'weight': 12.5,
    });
    expect(legacy.catalogId, isNull);
    expect(legacy.definition, isNull);
    expect(Exercise.fromJson(legacy.toJson()).name, '原有自定义动作');
  });
}
