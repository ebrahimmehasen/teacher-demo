import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/labels.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../data/models/models.dart';
import '../../../data/repository_providers.dart';
import '../../../services/group_service.dart';
import '../../../services/tenant_data.dart';

/// Add (group == null) or edit a group. [initialSlot] pre-selects a day/period.
Future<void> showGroupFormDialog(
  BuildContext context, {
  required String tenantId,
  Group? group,
  (int weekday, int periodIndex)? initialSlot,
}) {
  final phone = MediaQuery.sizeOf(context).width < 600;
  final form = _GroupForm(tenantId: tenantId, group: group, initialSlot: initialSlot);
  return showDialog<void>(
    context: context,
    builder: (_) => phone
        ? Dialog.fullscreen(child: form)
        : Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 760),
              child: form,
            ),
          ),
  );
}

class _SessionDraft {
  _SessionDraft({required this.periodIndex, required this.start, required this.end});
  int periodIndex;
  ClockTime start;
  ClockTime end;
}

class _GroupForm extends ConsumerStatefulWidget {
  const _GroupForm({required this.tenantId, this.group, this.initialSlot});

  final String tenantId;
  final Group? group;
  final (int, int)? initialSlot;

  @override
  ConsumerState<_GroupForm> createState() => _GroupFormState();
}

class _GroupFormState extends ConsumerState<_GroupForm> {
  var _step = 0;
  var _saving = false;
  String? _error;

  String? _gradeId;
  final _number = TextEditingController();
  var _numberEdited = false;
  var _type = GroupType.public;
  final _price = TextEditingController();
  final _address = TextEditingController();
  final _capacity = TextEditingController();
  final _sessions = <int, _SessionDraft>{};

  @override
  void initState() {
    super.initState();
    final g = widget.group;
    if (g != null) {
      _gradeId = g.gradeId;
      _number.text = '${g.number}';
      _numberEdited = true;
      _type = g.type;
      _price.text = g.price?.toStringAsFixed(0) ?? '';
      _address.text = g.address ?? '';
      _capacity.text = '${g.capacity}';
      for (final s in g.sessions) {
        _sessions[s.weekday] = _SessionDraft(
          periodIndex: s.periodIndex,
          start: s.startTime,
          end: s.endTime,
        );
      }
    }
  }

  @override
  void dispose() {
    _number.dispose();
    _price.dispose();
    _address.dispose();
    _capacity.dispose();
    super.dispose();
  }

  List<Grade> get _grades => ref.read(gradesProvider).asData?.value ?? const [];
  List<Group> get _groups => ref.read(groupsProvider).asData?.value ?? const [];
  int get _periodCount => ref.read(periodsProvider).asData?.value?.count ?? 6;
  Grade? get _grade => _grades.where((g) => g.id == _gradeId).firstOrNull;

  int get _enrolled => widget.group == null
      ? 0
      : GroupService.enrolledCount(
          widget.group!.id,
          ref.read(enrollmentsProvider).asData?.value ?? const [],
        );

  void _selectGrade(String? gradeId) {
    setState(() {
      _gradeId = gradeId;
      final grade = _grade;
      if (grade == null) return;
      if (!_numberEdited) _number.text = '${GroupService.nextNumber(grade.id, _groups)}';
      if (_capacity.text.isEmpty) _capacity.text = '${grade.defaultCapacity}';
    });
  }

  void _addDay(int weekday) {
    final slot = widget.initialSlot;
    final period = slot != null && slot.$1 == weekday
        ? slot.$2
        : (_sessions.values.firstOrNull?.periodIndex ?? 0);
    final start = GroupService.defaultStart(period, _groups);
    _sessions[weekday] = _SessionDraft(
      periodIndex: period,
      start: start,
      end: start.addMinutes(GroupService.defaultSessionMinutes),
    );
  }

  List<GroupSession> get _draftSessions => [
    for (final entry in _sessions.entries)
      GroupSession(
        weekday: entry.key,
        periodIndex: entry.value.periodIndex,
        startTime: entry.value.start,
        endTime: entry.value.end,
      ),
  ];

  /// Validates the current step; returns an error message or null.
  String? _validate(int step) {
    switch (step) {
      case 0:
        if (_grade == null) return 'اختر الصف';
        final n = int.tryParse(_number.text);
        if (n == null || n < 1) return 'رقم المجموعة غير صحيح';
        final duplicate = _groups.any(
          (g) => g.gradeId == _gradeId && g.number == n && g.id != widget.group?.id,
        );
        if (duplicate) return 'يوجد مجموعة بنفس الرقم في هذا الصف';
      case 1:
        if (_type == GroupType.private) {
          if (Validators.positiveNumber(_price.text) != null) return 'أدخل سعر المجموعة الخاصة';
          if (_address.text.trim().isEmpty) return 'أدخل عنوان المجموعة الخاصة';
        }
      case 2:
        final c = int.tryParse(_capacity.text);
        if (c == null || c < 1) return 'أدخل سعة صحيحة';
        if (c < _enrolled) return 'السعة لا تقل عن عدد الطلاب الحاليين ($_enrolled)';
      case 3:
        if (_sessions.isEmpty) return 'اختر يوماً واحداً على الأقل';
        for (final s in _sessions.values) {
          if (s.end.compareTo(s.start) <= 0) return 'وقت النهاية يجب أن يكون بعد البداية';
        }
        final conflicts = GroupService.conflictingGroups(
          _draftSessions,
          _groups,
          ignoreGroupId: widget.group?.id,
        );
        if (conflicts.isNotEmpty) {
          final names = conflicts.map(_groupName).join('، ');
          return 'تعارض في المواعيد مع: $names';
        }
    }
    return null;
  }

  String _groupName(Group g) {
    final grade = _grades.where((x) => x.id == g.gradeId).firstOrNull;
    return '${grade?.name ?? ''} – ${GroupLabels.name(g.number)}';
  }

  void _next() {
    final error = _validate(_step);
    setState(() => _error = error);
    if (error != null) return;
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _save();
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final isPrivate = _type == GroupType.private;
    final existing = widget.group;
    final sessions = _draftSessions
      ..sort(
        (a, b) =>
            AppDates.weekOrder.indexOf(a.weekday).compareTo(AppDates.weekOrder.indexOf(b.weekday)),
      );
    final group = Group(
      id: existing?.id ?? const Uuid().v4(),
      tenantId: widget.tenantId,
      gradeId: _gradeId!,
      number: int.parse(_number.text),
      type: _type,
      capacity: int.parse(_capacity.text),
      price: isPrivate ? double.parse(_price.text) : null,
      address: isPrivate ? _address.text.trim() : null,
      sessions: sessions,
    );
    final repo = ref.read(groupRepositoryProvider);
    await (existing == null ? repo.add(group) : repo.update(group));
    if (!mounted) return;
    showSuccessSnack(context, existing == null ? 'تمت إضافة المجموعة' : 'تم حفظ التعديلات');
    Navigator.of(context).pop();
  }

  Future<void> _pickTime(_SessionDraft s, {required bool start}) async {
    final initial = start ? s.start : s.end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );
    if (picked == null) return;
    setState(() {
      final value = ClockTime(picked.hour, picked.minute);
      if (start) {
        final duration = s.end.inMinutes - s.start.inMinutes;
        s.start = value;
        s.end = value.addMinutes(duration > 0 ? duration : GroupService.defaultSessionMinutes);
      } else {
        s.end = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final digits = [FilteringTextInputFormatter.digitsOnly];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.group == null ? 'إضافة مجموعة' : 'تعديل المجموعة',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'إغلاق',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stepper(
            currentStep: _step,
            onStepTapped: (i) {
              if (i < _step) setState(() => _step = i);
            },
            onStepContinue: _saving ? null : _next,
            onStepCancel: _step == 0 ? null : () => setState(() => _step--),
            controlsBuilder: (context, details) => Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                    ),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: details.onStepContinue,
                        child: _saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(details.currentStep == 3 ? 'حفظ المجموعة' : 'التالي'),
                      ),
                      const SizedBox(width: 8),
                      if (details.onStepCancel != null)
                        TextButton(onPressed: details.onStepCancel, child: const Text('رجوع')),
                    ],
                  ),
                ],
              ),
            ),
            steps: [
              Step(
                title: const Text('الصف ورقم المجموعة'),
                isActive: _step >= 0,
                state: _step > 0 ? StepState.complete : StepState.indexed,
                content: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _gradeId,
                      decoration: const InputDecoration(labelText: 'الصف'),
                      items: [
                        for (final g in _grades) DropdownMenuItem(value: g.id, child: Text(g.name)),
                      ],
                      onChanged: _selectGrade,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _number,
                      keyboardType: TextInputType.number,
                      inputFormatters: digits,
                      onChanged: (_) => _numberEdited = true,
                      decoration: InputDecoration(
                        labelText: 'رقم المجموعة',
                        helperText: int.tryParse(_number.text) == null
                            ? null
                            : GroupLabels.name(int.parse(_number.text)),
                      ),
                    ),
                  ],
                ),
              ),
              Step(
                title: const Text('نوع المجموعة'),
                isActive: _step >= 1,
                state: _step > 1 ? StepState.complete : StepState.indexed,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<GroupType>(
                      segments: [
                        for (final t in GroupType.values)
                          ButtonSegment(
                            value: t,
                            label: Text(t.label),
                            icon: Icon(
                              t == GroupType.private
                                  ? Icons.location_on_outlined
                                  : Icons.groups_outlined,
                            ),
                          ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (s) => setState(() => _type = s.first),
                    ),
                    const SizedBox(height: 12),
                    if (_type == GroupType.public)
                      Text(
                        _grade == null
                            ? 'سعر المجموعة العامة هو سعر الصف.'
                            : 'السعر: ${Money.format(_grade!.publicPrice)} شهرياً (سعر الصف)',
                        style: theme.textTheme.bodyMedium,
                      )
                    else ...[
                      TextField(
                        controller: _price,
                        keyboardType: TextInputType.number,
                        inputFormatters: digits,
                        decoration: const InputDecoration(
                          labelText: 'سعر الشهر',
                          suffixText: 'ج.م',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _address,
                        decoration: const InputDecoration(
                          labelText: 'العنوان',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Step(
                title: const Text('السعة'),
                isActive: _step >= 2,
                state: _step > 2 ? StepState.complete : StepState.indexed,
                content: TextField(
                  controller: _capacity,
                  keyboardType: TextInputType.number,
                  inputFormatters: digits,
                  decoration: InputDecoration(
                    labelText: 'أقصى عدد للطلاب',
                    suffixText: 'طالب',
                    helperText: _enrolled > 0 ? 'مسجل حالياً: $_enrolled طالب' : null,
                  ),
                ),
              ),
              Step(
                title: const Text('الأيام والمواعيد'),
                isActive: _step >= 3,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final day in AppDates.weekOrder)
                          FilterChip(
                            label: Text(AppDates.weekdayName(day)),
                            selected: _sessions.containsKey(day),
                            onSelected: (v) => setState(() {
                              v ? _addDay(day) : _sessions.remove(day);
                            }),
                          ),
                      ],
                    ),
                    for (final day in AppDates.weekOrder)
                      if (_sessions[day] case final s?)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SizedBox(
                                width: 72,
                                child: Text(
                                  AppDates.weekdayName(day),
                                  style: theme.textTheme.titleSmall,
                                ),
                              ),
                              DropdownButton<int>(
                                value: s.periodIndex < _periodCount ? s.periodIndex : 0,
                                items: [
                                  for (var p = 0; p < _periodCount; p++)
                                    DropdownMenuItem(value: p, child: Text('الفترة ${p + 1}')),
                                ],
                                onChanged: (p) => setState(() {
                                  if (p == null) return;
                                  s.periodIndex = p;
                                  s.start = GroupService.defaultStart(p, _groups);
                                  s.end = s.start.addMinutes(GroupService.defaultSessionMinutes);
                                }),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _pickTime(s, start: true),
                                icon: const Icon(Icons.schedule, size: 18),
                                label: Text('من ${AppDates.clock(s.start)}'),
                              ),
                              OutlinedButton(
                                onPressed: () => _pickTime(s, start: false),
                                child: Text('إلى ${AppDates.clock(s.end)}'),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
