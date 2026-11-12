import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/workout.dart';
import '../theme.dart';
import 'common.dart';
import 'exercise_picker.dart';

class WorkoutEditor extends StatefulWidget {
  const WorkoutEditor({
    super.key,
    required this.date,
    required this.onSave,
    this.existing,
  });

  final DateTime date;
  final Workout? existing;
  final Future<void> Function(Workout) onSave;

  @override
  State<WorkoutEditor> createState() => _WorkoutEditorState();
}

class _WorkoutEditorState extends State<WorkoutEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _note;
  late TrainingCategory _category;
  final _rows = <_ExerciseDraft>[];
  int _nextId = 0;
  bool _saving = false;
  bool _dirty = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _category = widget.existing?.category ?? TrainingCategory.chest;
    _note = TextEditingController(text: widget.existing?.note ?? '');
    for (final exercise in widget.existing?.exercises ?? <Exercise>[]) {
      _rows.add(_ExerciseDraft(_nextId++, exercise));
    }
  }

  @override
  void dispose() {
    _note.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _close() async {
    if (_saving) return;
    if (_dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('放弃这次修改？'),
          content: const Text('还没有保存的内容将不会被记录。'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('继续填写')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('放弃修改')),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final workout = Workout(
      date: widget.date,
      category: _category,
      note: _note.text.trim(),
      exercises: _category.isTraining
          ? _rows
              .map((row) => Exercise(
                    name: row.definition?.name ?? row.legacyName!,
                    catalogId: row.definition?.id,
                    sets: int.parse(row.sets.text),
                    reps: int.tryParse(row.reps.text),
                    weight: row.weightMode == WeightMode.standard
                        ? double.tryParse(row.weight.text)
                        : null,
                    weightMode: row.weightMode,
                    dropWeights: row.weightMode == WeightMode.dropSet
                        ? row.dropWeights
                            .map((weight) => double.parse(weight.text))
                            .toList()
                        : const [],
                  ))
              .toList()
          : widget.existing?.exercises ?? const [],
    );
    try {
      await widget.onSave(workout);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '保存失败，内容仍在。请检查设备存储空间后重试。';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final horizontalPadding = compact ? 22.0 : 30.0;
    return PopScope(
      canPop: !_saving && !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving) _close();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (compact)
            Center(
                child: Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(4)),
            )),
          Padding(
            padding: EdgeInsets.fromLTRB(
                horizontalPadding, compact ? 18 : 25, 14, 18),
            child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Eyebrow(_category.isTraining
                        ? 'A LITTLE STRONGER, EVERY DAY'
                        : 'ENJOY YOUR DAY'),
                    const SizedBox(height: 9),
                    Text(
                        _category.isTraining
                            ? (widget.existing == null ? '记录这一次训练' : '编辑训练记录')
                            : (widget.existing == null ? '记下这个放纵日' : '编辑放纵日'),
                        style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink)),
                    const SizedBox(height: 5),
                    Text('${widget.date.year} 年 ${friendlyDate(widget.date)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.muted)),
                  ])),
              IconButton(
                  onPressed: _saving ? null : _close,
                  tooltip: '关闭',
                  icon: const Icon(Icons.close_rounded, size: 21)),
            ]),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding, vertical: 23),
              child: Form(
                key: _formKey,
                onChanged: () {
                  if (!_dirty) setState(() => _dirty = true);
                },
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('01', '今天怎么过？'),
                      const SizedBox(height: 13),
                      LayoutBuilder(builder: (context, constraints) {
                        final columns = constraints.maxWidth > 440 ? 7 : 4;
                        final width =
                            (constraints.maxWidth - (columns - 1) * 8) /
                                columns;
                        return Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final category in TrainingCategory.values)
                            SizedBox(
                                width: width,
                                child: Semantics(
                                  selected: category == _category,
                                  button: true,
                                  label: category.displayName,
                                  child: Material(
                                    color: _category == category
                                        ? AppColors.forest
                                        : AppColors.pale,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      key: Key('category-${category.name}'),
                                      onTap: _saving
                                          ? null
                                          : () => setState(() {
                                                _category = category;
                                                _dirty = true;
                                              }),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 15),
                                        child: Text(category.label,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 25,
                                              fontWeight: FontWeight.w600,
                                              color: _category == category
                                                  ? AppColors.lime
                                                  : AppColors.ink,
                                            )),
                                      ),
                                    ),
                                  ),
                                )),
                        ]);
                      }),
                      const SizedBox(height: 10),
                      Text(
                        _category.isTraining
                            ? '胸、肩、背、腿、臂、腹是训练部位；纵 = 放纵日。'
                            : '放纵日只记录备注，不计入训练天数、组数和容量。',
                        style: const TextStyle(
                            fontSize: 10, height: 1.7, color: AppColors.muted),
                      ),
                      const SizedBox(height: 27),
                      _sectionTitle(
                          '02', _category.isTraining ? '训练备注' : '放纵日备注',
                          trailing: '选填'),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('note-input'),
                        controller: _note,
                        enabled: !_saving,
                        minLines: 3,
                        maxLines: 7,
                        maxLength: 5000,
                        style: const TextStyle(fontSize: 13, height: 1.8),
                        decoration: InputDecoration(
                          hintText: _category.isTraining
                              ? '杠铃卧推 4 组 × 10 次，60 kg\n今天状态不错，下一次试着加一点重量。'
                              : '今天给自己放个假，记下想吃的、想做的，或此刻的心情。',
                          counterText: '',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                          _category.isTraining
                              ? '备注不会自动统计，动作与重量请在下方明细中记录。'
                              : '纵是放纵日，不是训练部位。享受生活，也值得被记录。',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.muted)),
                      if (_category.isTraining) ...[
                        const SizedBox(height: 26),
                        _sectionTitle('03', '动作明细', trailing: '选填 · 自动统计组数与容量'),
                        const SizedBox(height: 12),
                        for (final row in _rows) ...[
                          _exerciseRow(row),
                          const SizedBox(height: 10),
                        ],
                        SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              key: const Key('add-exercise'),
                              onPressed: _saving
                                  ? null
                                  : () => setState(() {
                                        _rows.add(_ExerciseDraft(_nextId++));
                                        _dirty = true;
                                      }),
                              icon: const Icon(Icons.add_rounded, size: 17),
                              label: const Text('添加动作',
                                  style: TextStyle(fontSize: 12)),
                            )),
                      ] else if (widget.existing?.exercises.isNotEmpty ??
                          false) ...[
                        const SizedBox(height: 16),
                        const Text('原有动作明细会保留，但不计入训练统计。',
                            style: TextStyle(
                                fontSize: 10, color: AppColors.muted)),
                      ],
                      if (_error != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                  color: AppColors.danger, fontSize: 12),
                            )),
                    ]),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(
                horizontalPadding, 16, horizontalPadding, 20),
            child: Row(children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 13, color: AppColors.muted),
              const SizedBox(width: 5),
              const Expanded(
                  child: Text('只为自己记录',
                      style: TextStyle(fontSize: 11, color: AppColors.muted))),
              FilledButton.icon(
                key: const Key('save-workout'),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_rounded, size: 17),
                label: Text(_saving
                    ? '保存中…'
                    : (_category.isTraining ? '保存训练' : '保存放纵日')),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String number, String title, {String? trailing}) => Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Text(number, style: numberStyle(11, color: AppColors.muted)),
          Text(title,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          if (trailing != null)
            Text(trailing,
                style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        ],
      );

  Widget _exerciseRow(_ExerciseDraft row) => Container(
        key: ValueKey(row.id),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: FormField<ExerciseDefinition>(
              initialValue: row.definition,
              validator: (_) => row.definition == null && row.legacyName == null
                  ? '请选择训练动作'
                  : null,
              builder: (field) => InkWell(
                key: Key('exercise-selector-${row.id}'),
                onTap: _saving
                    ? null
                    : () async {
                        FocusScope.of(context).unfocus();
                        final selected =
                            await showWorkoutModal<ExerciseDefinition>(
                          context: context,
                          builder: (_) => ExercisePicker(
                            initialCategory:
                                row.definition?.category ?? _category,
                            selectedId: row.definition?.id,
                          ),
                        );
                        if (selected == null || !mounted) return;
                        setState(() {
                          row.definition = selected;
                          row.legacyName = null;
                          _dirty = true;
                        });
                        field.didChange(selected);
                      },
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: '训练动作',
                    errorText: field.errorText,
                    suffixIcon: const Icon(Icons.unfold_more_rounded, size: 18),
                  ),
                  child: Text(
                    row.definition == null
                        ? row.legacyName == null
                            ? '部位 / 选择动作'
                            : '历史动作 / ${row.legacyName}'
                        : '${row.definition!.category.label} / ${row.definition!.name}',
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: row.definition == null && row.legacyName == null
                            ? AppColors.muted
                            : AppColors.ink),
                  ),
                ),
              ),
            )),
            IconButton(
              onPressed: _saving
                  ? null
                  : () => setState(() {
                        _rows.remove(row);
                        _dirty = true;
                        // Dispose after the removed text fields have left the widget tree.
                        WidgetsBinding.instance
                            .addPostFrameCallback((_) => row.dispose());
                      }),
              tooltip: '移除此动作',
              icon: const Icon(Icons.close_rounded,
                  size: 17, color: AppColors.muted),
            ),
          ]),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(spacing: 8, runSpacing: 4, children: [
              for (final mode in WeightMode.values)
                ChoiceChip(
                  key: Key(
                      'weight-${mode == WeightMode.standard ? 'standard' : 'drop'}-${row.id}'),
                  label: Text(mode == WeightMode.standard ? '标准重量' : '递减重量',
                      style: const TextStyle(fontSize: 11)),
                  selected: row.weightMode == mode,
                  showCheckmark: false,
                  selectedColor: AppColors.pale,
                  onSelected: _saving
                      ? null
                      : (_) => setState(() {
                            row.weightMode = mode;
                            if (mode == WeightMode.dropSet &&
                                row.dropWeights.isEmpty) {
                              row.dropWeights.addAll([
                                TextEditingController(text: row.weight.text),
                                TextEditingController(),
                              ]);
                            }
                            _dirty = true;
                          }),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: _numberField(
                    row.sets, '组数', '组', 'exercise-sets-${row.id}',
                    required: true)),
            const SizedBox(width: 8),
            Expanded(
                child: _numberField(
                    row.reps,
                    row.weightMode == WeightMode.dropSet ? '每级次数' : '每组次数',
                    '次',
                    'exercise-reps-${row.id}')),
          ]),
          const SizedBox(height: 12),
          if (row.weightMode == WeightMode.standard) ...[
            _numberField(row.weight, '重量', 'kg', 'exercise-weight-${row.id}',
                decimal: true),
            const SizedBox(height: 7),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('自重填 0；重量、次数可留空，但不计训练容量。',
                  style: TextStyle(fontSize: 10, color: AppColors.muted)),
            ),
          ] else ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('至少两个重量，按从大到小填写；自重可填 0。',
                  style: TextStyle(fontSize: 10, color: AppColors.muted)),
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < row.dropWeights.length; index++)
              Padding(
                key: ObjectKey(row.dropWeights[index]),
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: _numberField(
                        row.dropWeights[index],
                        '第 ${index + 1} 级重量',
                        'kg',
                        'exercise-drop-weight-${row.id}-$index',
                        required: true,
                        decimal: true,
                        extraValidator: (value) {
                          if (index == 0) return null;
                          final previous =
                              double.tryParse(row.dropWeights[index - 1].text);
                          final current = double.tryParse(value ?? '');
                          return previous != null &&
                                  current != null &&
                                  current >= previous
                              ? '需小于上一级重量'
                              : null;
                        },
                      )),
                      if (row.dropWeights.length > 2)
                        IconButton(
                          key: Key('remove-drop-weight-${row.id}-$index'),
                          onPressed: _saving
                              ? null
                              : () => setState(() {
                                    final removed =
                                        row.dropWeights.removeAt(index);
                                    _dirty = true;
                                    WidgetsBinding.instance
                                        .addPostFrameCallback(
                                            (_) => removed.dispose());
                                  }),
                          tooltip: '移除此级重量',
                          icon: const Icon(Icons.remove_circle_outline_rounded,
                              size: 19, color: AppColors.muted),
                        ),
                    ]),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: Key('add-drop-weight-${row.id}'),
                onPressed: _saving
                    ? null
                    : () => setState(() {
                          row.dropWeights.add(TextEditingController());
                          _dirty = true;
                        }),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('增加一级重量', style: TextStyle(fontSize: 11)),
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('每组依次完成所有重量；次数为每级次数，未填则不计容量。',
                  style: TextStyle(
                      fontSize: 10, height: 1.7, color: AppColors.muted)),
            ),
          ],
        ]),
      );

  Widget _numberField(TextEditingController controller, String label,
          String unit, String key,
          {bool required = false,
          bool decimal = false,
          String? Function(String?)? extraValidator}) =>
      TextFormField(
        key: Key(key),
        controller: controller,
        enabled: !_saving,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        inputFormatters: [
          decimal
              ? TextInputFormatter.withFunction((oldValue, newValue) =>
                  RegExp(r'^\d{0,4}(\.\d{0,2})?$').hasMatch(newValue.text)
                      ? newValue
                      : oldValue)
              : FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(decimal ? 7 : 4),
        ],
        style: const TextStyle(fontFamily: 'Manrope', fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
          suffixStyle: const TextStyle(fontSize: 9, color: AppColors.muted),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return required ? (decimal ? '请填写重量' : '请填组数') : null;
          }
          final number = num.tryParse(value);
          if (number == null ||
              !number.isFinite ||
              number < (decimal ? 0 : 1) ||
              number > (required && !decimal ? 999 : 9999)) {
            return '数值无效';
          }
          return extraValidator?.call(value);
        },
      );
}

class _ExerciseDraft {
  _ExerciseDraft(this.id, [Exercise? exercise])
      : definition = exercise?.definition,
        legacyName = exercise?.definition == null ? exercise?.name : null,
        weightMode = exercise?.weightMode ?? WeightMode.standard,
        dropWeights = [
          for (final weight in exercise?.dropWeights ?? <double>[])
            TextEditingController(text: _format(weight)),
        ],
        sets = TextEditingController(text: exercise?.sets.toString() ?? '4'),
        reps = TextEditingController(text: exercise?.reps?.toString() ?? ''),
        weight = TextEditingController(
            text: exercise?.weight == null ? '' : _format(exercise!.weight!));

  final int id;
  ExerciseDefinition? definition;
  String? legacyName;
  WeightMode weightMode;
  final List<TextEditingController> dropWeights;
  final TextEditingController sets;
  final TextEditingController reps;
  final TextEditingController weight;

  static String _format(double value) =>
      value == value.roundToDouble() ? '${value.toInt()}' : '$value';

  void dispose() {
    sets.dispose();
    reps.dispose();
    weight.dispose();
    for (final weight in dropWeights) {
      weight.dispose();
    }
  }
}
