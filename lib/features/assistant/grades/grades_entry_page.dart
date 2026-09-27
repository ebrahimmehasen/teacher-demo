import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/filter_dropdown.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../data/models/models.dart';
import '../../../services/assessment_service.dart';
import '../../../services/tenant_data.dart';

class GradesEntryPage extends ConsumerStatefulWidget {
  const GradesEntryPage({super.key});

  @override
  ConsumerState<GradesEntryPage> createState() => _GradesEntryPageState();
}

class _GradesEntryPageState extends ConsumerState<GradesEntryPage> {
  String? _assessmentId;
  final _draft = <String, ResultEntry>{};
  String? _loadedFor;
  var _saving = false;
  String? _error;

  void _load(Assessment assessment, List<AssessmentResult> results) {
    if (_loadedFor == assessment.id) return;
    _loadedFor = assessment.id;
    _error = null;
    _draft
      ..clear()
      ..addAll({
        for (final r in results.where((r) => r.assessmentId == assessment.id))
          r.studentId: ResultEntry(delivered: r.delivered, score: r.score),
      });
  }

  Future<void> _save(Assessment assessment, List<AssessmentResult> results) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(assessmentServiceProvider).saveResults(assessment, Map.of(_draft), results);
      if (mounted) showSuccessSnack(context, 'تم حفظ النتائج (${_draft.length} طالب)');
    } on ArgumentError catch (e) {
      if (mounted) setState(() => _error = e.message.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assessments = ref.watch(assessmentsProvider).asData?.value ?? const <Assessment>[];
    final results =
        ref.watch(assessmentResultsProvider).asData?.value ?? const <AssessmentResult>[];
    final grades = {
      for (final g in ref.watch(gradesProvider).asData?.value ?? const <Grade>[]) g.id: g.name,
    };
    final groups = ref.watch(groupsProvider).asData?.value ?? const <Group>[];
    final enrollments = ref.watch(enrollmentsProvider).asData?.value ?? const <Enrollment>[];
    final users = ref.watch(tenantStudentsProvider).asData?.value ?? const <String, User>{};

    if (assessments.isEmpty) {
      return const EmptyState(
        icon: Icons.assignment_outlined,
        title: 'لا توجد واجبات أو امتحانات بعد',
        message: 'يضيفها المدرس من صفحة الواجبات والامتحانات.',
      );
    }
    _assessmentId ??= assessments.first.id;
    final assessment = assessments.firstWhere(
      (a) => a.id == _assessmentId,
      orElse: () => assessments.first,
    );
    _load(assessment, results);

    final gradeGroups = {
      for (final g in groups.where((g) => g.gradeId == assessment.gradeId)) g.id,
    };
    final students = [
      for (final e in enrollments)
        if (e.active && gradeGroups.contains(e.groupId) && users[e.studentId] != null)
          users[e.studentId]!,
    ]..sort((a, b) => a.name.compareTo(b.name));
    final hasScore = assessment.maxScore != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterDropdown<String>(
                label: 'الواجب / الامتحان',
                width: 360,
                allLabel: null,
                value: _assessmentId,
                items: {
                  for (final a in assessments)
                    a.id:
                        '${a.type == AssessmentType.exam ? 'امتحان' : 'واجب'}: ${a.title} – ${grades[a.gradeId] ?? ''}',
                },
                onChanged: (v) => setState(() => _assessmentId = v),
              ),
              Text(
                '${AppDates.dayMonth(assessment.date)}'
                '${hasScore ? ' • الدرجة من ${assessment.maxScore!.toStringAsFixed(0)}' : ' • تسليم فقط'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: students.isEmpty
              ? const EmptyState(icon: Icons.groups_outlined, title: 'لا يوجد طلاب في هذا الصف')
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: students.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final s = students[i];
                    final entry = _draft[s.id] ?? const ResultEntry(delivered: false);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Checkbox(
                            value: entry.delivered,
                            onChanged: (v) => setState(
                              () => _draft[s.id] = ResultEntry(
                                delivered: v ?? false,
                                score: entry.score,
                              ),
                            ),
                          ),
                          Expanded(child: Text(s.name)),
                          if (hasScore)
                            SizedBox(
                              width: 110,
                              // "28 / 50" reads naturally only left-to-right.
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: TextFormField(
                                  key: ValueKey('${assessment.id}-${s.id}'),
                                  initialValue: entry.score == null ? '' : _fmt(entry.score!),
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                                  ],
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: '—',
                                    suffixText: '/${assessment.maxScore!.toStringAsFixed(0)}',
                                  ),
                                  onChanged: (v) {
                                    final score = double.tryParse(v);
                                    setState(
                                      () => _draft[s.id] = ResultEntry(
                                        delivered: score != null || entry.delivered,
                                        score: score,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _error ??
                        'سلّم ${_draft.values.where((e) => e.delivered).length} من ${students.length}',
                    style: TextStyle(
                      color: _error == null ? null : Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _saving || _draft.isEmpty ? null : () => _save(assessment, results),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('حفظ النتائج'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';
}
