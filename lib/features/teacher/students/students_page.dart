import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/labels.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/filter_dropdown.dart';
import '../../../core/widgets/search_filter_bar.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/models.dart';
import '../../../services/enrollment_service.dart';
import '../../../services/group_service.dart';
import '../../../services/payment_status_service.dart';
import '../../../services/tenant_data.dart';
import 'bulk_action_dialogs.dart';
import 'student_detail_sheet.dart';
import '../../shared/students/student_rows.dart';

class StudentsPage extends ConsumerStatefulWidget {
  const StudentsPage({super.key});

  @override
  ConsumerState<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends ConsumerState<StudentsPage> {
  var _filter = const StudentFilter();
  final _selected = <String>{};
  var _busy = false;

  List<Enrollment> _selectedEnrollments(List<StudentRow> rows) => [
    for (final r in rows)
      if (_selected.contains(r.enrollment.id)) r.enrollment,
  ];

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      setState(_selected.clear);
      showSuccessSnack(context, success);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exempt(List<StudentRow> rows, bool exempt) => _run(
    () => ref.read(enrollmentActionsProvider).setExempt(_selectedEnrollments(rows), exempt: exempt),
    exempt ? 'تم إعفاء الطلاب المحددين' : 'تم إلغاء الإعفاء',
  );

  Future<void> _discount(List<StudentRow> rows) async {
    final percent = await showDiscountDialog(context);
    if (percent == null) return;
    await _run(
      () => ref.read(enrollmentActionsProvider).setDiscount(_selectedEnrollments(rows), percent),
      percent == 0 ? 'تم إلغاء الخصم' : 'تم تطبيق خصم $percent%',
    );
  }

  Future<void> _move(List<StudentRow> rows) async {
    final groups = ref.read(groupsProvider).asData?.value ?? const <Group>[];
    final grades = {
      for (final g in ref.read(gradesProvider).asData?.value ?? const <Grade>[]) g.id: g,
    };
    final all = ref.read(enrollmentsProvider).asData?.value ?? const <Enrollment>[];
    final target = await showMoveGroupDialog(
      context,
      groups: groups,
      grades: grades,
      enrollments: all,
    );
    if (target == null || !mounted) return;
    try {
      await _run(
        () => ref.read(enrollmentActionsProvider).moveTo(target, _selectedEnrollments(rows), all),
        'تم نقل الطلاب إلى ${GroupLabels.name(target.number)}',
      );
    } on CapacityException catch (e) {
      if (mounted) await showGroupFullAlert(context, e.group, grades[e.group.gradeId]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grades = ref.watch(gradesProvider).asData?.value ?? const <Grade>[];
    final groups = ref.watch(groupsProvider).asData?.value ?? const <Group>[];
    final gradeNames = {for (final g in grades) g.id: g.name};

    return AsyncValueView(
      value: ref.watch(studentRowsProvider),
      builder: (allRows) {
        final rows = allRows.where(_filter.matches).toList();
        final visibleIds = {for (final r in rows) r.enrollment.id};
        _selected.retainWhere(visibleIds.contains);
        void toggle(String id, bool v) =>
            setState(() => v ? _selected.add(id) : _selected.remove(id));

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: SearchFilterBar(
                    onSearch: (q) => setState(
                      () => _filter = StudentFilter(
                        query: q,
                        gradeId: _filter.gradeId,
                        groupId: _filter.groupId,
                        status: _filter.status,
                      ),
                    ),
                    filters: [
                      FilterDropdown<String>(
                        label: 'الصف',
                        value: _filter.gradeId,
                        items: {for (final g in grades) g.id: g.name},
                        onChanged: (v) => setState(
                          () => _filter = StudentFilter(
                            query: _filter.query,
                            gradeId: v,
                            status: _filter.status,
                          ),
                        ),
                      ),
                      FilterDropdown<String>(
                        label: 'المجموعة',
                        value: _filter.groupId,
                        items: {
                          for (final g in groups)
                            if (_filter.gradeId == null || g.gradeId == _filter.gradeId)
                              g.id:
                                  '${gradeNames[g.gradeId] ?? ''} – ${GroupLabels.name(g.number)}',
                        },
                        onChanged: (v) => setState(
                          () => _filter = StudentFilter(
                            query: _filter.query,
                            gradeId: _filter.gradeId,
                            groupId: v,
                            status: _filter.status,
                          ),
                        ),
                      ),
                      FilterDropdown<PaymentStatus>(
                        label: 'حالة الدفع',
                        value: _filter.status,
                        items: {for (final s in PaymentStatus.values) s: s.label},
                        onChanged: (v) => setState(
                          () => _filter = StudentFilter(
                            query: _filter.query,
                            gradeId: _filter.gradeId,
                            groupId: _filter.groupId,
                            status: v,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _SelectionBar(
                  showSelectAll: !wide,
                  total: rows.length,
                  selected: _selected.length,
                  busy: _busy,
                  onSelectAll: (all) => setState(() {
                    all ? _selected.addAll(visibleIds) : _selected.clear();
                  }),
                  onExempt: () => _exempt(rows, true),
                  onUnexempt: () => _exempt(rows, false),
                  onDiscount: () => _discount(rows),
                  onMove: () => _move(rows),
                ),
                const Divider(height: 1),
                Expanded(
                  child: rows.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off,
                          title: 'لا يوجد طلاب مطابقون للبحث',
                        )
                      : wide
                      ? _StudentsTable(rows: rows, selected: _selected, onToggle: toggle)
                      : _StudentsList(rows: rows, selected: _selected, onToggle: toggle),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.showSelectAll,
    required this.total,
    required this.selected,
    required this.busy,
    required this.onSelectAll,
    required this.onExempt,
    required this.onUnexempt,
    required this.onDiscount,
    required this.onMove,
  });

  /// The wide table has its own header checkbox.
  final bool showSelectAll;
  final int total;
  final int selected;
  final bool busy;
  final ValueChanged<bool> onSelectAll;
  final VoidCallback onExempt;
  final VoidCallback onUnexempt;
  final VoidCallback onDiscount;
  final VoidCallback onMove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = selected > 0 && !busy;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSelectAll)
                Checkbox(
                  tristate: true,
                  value: selected == 0 ? false : (selected == total ? true : null),
                  onChanged: total == 0 ? null : (_) => onSelectAll(selected != total),
                )
              else
                const SizedBox(width: 12),
              Text(
                selected == 0 ? '$total طالب' : 'تم تحديد $selected من $total',
                style: theme.textTheme.titleSmall,
              ),
              if (busy)
                const Padding(
                  padding: EdgeInsetsDirectional.only(start: 12),
                  child: SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: active ? onExempt : null,
            icon: const Icon(Icons.remove_circle_outline),
            label: const Text('إعفاء'),
          ),
          TextButton.icon(
            onPressed: active ? onUnexempt : null,
            icon: const Icon(Icons.undo),
            label: const Text('إلغاء الإعفاء'),
          ),
          TextButton.icon(
            onPressed: active ? onDiscount : null,
            icon: const Icon(Icons.percent),
            label: const Text('خصم'),
          ),
          TextButton.icon(
            onPressed: active ? onMove : null,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('نقل مجموعة'),
          ),
        ],
      ),
    );
  }
}

String _priceLabel(StudentRow r) {
  if (r.enrollment.isExempt) return 'معفى';
  final base = Money.format(r.billing.price);
  return r.enrollment.discountPercent > 0 ? '$base (خصم ${r.enrollment.discountPercent}%)' : base;
}

String _groupLabel(StudentRow r) => '${r.grade.name} – ${GroupLabels.name(r.group.number)}';

class _StudentsTable extends StatelessWidget {
  const _StudentsTable({required this.rows, required this.selected, required this.onToggle});

  final List<StudentRow> rows;
  final Set<String> selected;
  final void Function(String enrollmentId, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          showCheckboxColumn: true,
          headingTextStyle: const TextStyle(fontWeight: FontWeight.w700),
          columns: const [
            DataColumn(label: Text('الطالب')),
            DataColumn(label: Text('المجموعة')),
            DataColumn(label: Text('الاشتراك الشهري')),
            DataColumn(label: Text('المدفوع هذا الشهر')),
            DataColumn(label: Text('الحالة')),
            DataColumn(label: Text('')),
          ],
          rows: [
            for (final r in rows)
              DataRow(
                selected: selected.contains(r.enrollment.id),
                onSelectChanged: (v) => onToggle(r.enrollment.id, v ?? false),
                cells: [
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.student.name),
                        Text(r.student.phone, style: muted, textDirection: TextDirection.ltr),
                      ],
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (r.group.isPrivate)
                          const Padding(
                            padding: EdgeInsetsDirectional.only(end: 4),
                            child: Icon(Icons.location_on_outlined, size: 16),
                          ),
                        Text(_groupLabel(r)),
                      ],
                    ),
                  ),
                  DataCell(Text(_priceLabel(r))),
                  DataCell(Text(Money.format(r.billing.paid))),
                  DataCell(StatusChip.payment(r.billing.status)),
                  DataCell(
                    IconButton(
                      tooltip: 'عرض التفاصيل',
                      icon: const Icon(Icons.info_outline),
                      onPressed: () => showStudentDetailSheet(
                        context,
                        StudentRowLike(
                          studentId: r.student.id,
                          name: r.student.name,
                          phone: r.student.phone,
                          groupLabel: _groupLabel(r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StudentsList extends StatelessWidget {
  const _StudentsList({required this.rows, required this.selected, required this.onToggle});

  final List<StudentRow> rows;
  final Set<String> selected;
  final void Function(String enrollmentId, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final r = rows[i];
        final isSelected = selected.contains(r.enrollment.id);
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onToggle(r.enrollment.id, !isSelected),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (v) => onToggle(r.enrollment.id, v ?? false),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.student.name, style: Theme.of(context).textTheme.titleSmall),
                        Text(_groupLabel(r), style: Theme.of(context).textTheme.bodySmall),
                        Text(_priceLabel(r), style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  StatusChip.payment(r.billing.status),
                  IconButton(
                    tooltip: 'عرض التفاصيل',
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => showStudentDetailSheet(
                      context,
                      StudentRowLike(
                        studentId: r.student.id,
                        name: r.student.name,
                        phone: r.student.phone,
                        groupLabel: _groupLabel(r),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
