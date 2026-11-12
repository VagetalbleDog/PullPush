import 'package:flutter/material.dart';

import '../models/training_catalog.dart';
import '../theme.dart';
import 'common.dart';

class ExercisePicker extends StatefulWidget {
  const ExercisePicker({
    super.key,
    required this.initialCategory,
    this.selectedId,
  });

  final TrainingCategory initialCategory;
  final String? selectedId;

  @override
  State<ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<ExercisePicker> {
  late TrainingCategory _category;
  final _optionsScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory.isTraining
        ? widget.initialCategory
        : TrainingCategory.chest;
  }

  @override
  void dispose() {
    _optionsScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 12, 18),
        child: Row(children: [
          const Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Eyebrow('BUILD YOUR MOVEMENT'),
              SizedBox(height: 7),
              Text('选择动作',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              SizedBox(height: 5),
              Text('先选部位，再选动作。每一次进步，都有名字。',
                  style: TextStyle(fontSize: 11, color: AppColors.muted)),
            ]),
          ),
          IconButton(
            key: const Key('close-exercise-picker'),
            onPressed: () => Navigator.pop(context),
            tooltip: '取消选择',
            icon: const Icon(Icons.close_rounded, size: 21),
          ),
        ]),
      ),
      const Divider(height: 1),
      Flexible(
        child: SizedBox(
          height: 440,
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 76,
              child: ColoredBox(
                color: AppColors.background,
                child: ListView(
                    primary: false,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    children: [
                      for (final category in TrainingCategory.training)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          child: TextButton(
                            key: Key('picker-category-${category.name}'),
                            onPressed: () {
                              if (_optionsScroll.hasClients) {
                                _optionsScroll.jumpTo(0);
                              }
                              setState(() => _category = category);
                            },
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              foregroundColor: _category == category
                                  ? AppColors.lime
                                  : AppColors.muted,
                              backgroundColor: _category == category
                                  ? AppColors.forest
                                  : Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(category.label,
                                style: const TextStyle(fontSize: 19)),
                          ),
                        ),
                    ]),
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: ListView(
                key: const Key('exercise-options-list'),
                controller: _optionsScroll,
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 0, 10),
                    child: Text(
                        '${_category.label}部 · ${ExerciseCatalog.forCategory(_category).length} 个动作',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.muted)),
                  ),
                  for (final exercise in ExerciseCatalog.forCategory(_category))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Material(
                        color: widget.selectedId == exercise.id
                            ? _category.tint
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: ListTile(
                          key: Key('picker-exercise-${exercise.id}'),
                          onTap: () => Navigator.pop(context, exercise),
                          selected: widget.selectedId == exercise.id,
                          selectedColor: AppColors.forest,
                          minTileHeight: 52,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          title: Text(exercise.name,
                              style:
                                  const TextStyle(fontSize: 13, height: 1.6)),
                          trailing: Icon(
                              widget.selectedId == exercise.id
                                  ? Icons.check_rounded
                                  : Icons.chevron_right_rounded,
                              size: 17,
                              color: AppColors.muted),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}
