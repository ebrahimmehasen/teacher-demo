import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/labels.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/filter_dropdown.dart';
import '../../../core/widgets/search_filter_bar.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/models.dart';
import '../../../services/tenant_data.dart';
import '../../shared/students/student_rows.dart';
import 'payment_form.dart';

class PaymentsPage extends ConsumerStatefulWidget {
  const PaymentsPage({super.key});

  @override
  ConsumerState<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends ConsumerState<PaymentsPage> {
  var _filter = const StudentFilter();
  String? _selectedId;

  Future<void> _openSheet(StudentRow row) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: PaymentForm(row: row, onSaved: () => Navigator.of(context).pop()),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final grades = ref.watch(gradesProvider).asData?.value ?? const <Grade>[];
    final groups = ref.watch(groupsProvider).asData?.value ?? const <Group>[];
    final labels = ref.watch(groupLabelsProvider);

    return AsyncValueView(
      value: ref.watch(studentRowsProvider),
      builder: (allRows) {
        final rows = allRows.where(_filter.matches).toList();
        final selected = allRows.where((r) => r.student.id == _selectedId).firstOrNull;

        Widget picker({required bool wide}) => Column(
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
                  ),
                ),
                filters: [
                  FilterDropdown<String>(
                    label: 'الصف',
                    width: 150,
                    value: _filter.gradeId,
                    items: {for (final g in grades) g.id: g.name},
                    onChanged: (v) =>
                        setState(() => _filter = StudentFilter(query: _filter.query, gradeId: v)),
                  ),
                  FilterDropdown<String>(
                    label: 'المجموعة',
                    width: 200,
                    value: _filter.groupId,
                    items: {
                      for (final g in groups)
                        if (_filter.gradeId == null || g.gradeId == _filter.gradeId)
                          g.id: labels[g.id] ?? '',
                    },
                    onChanged: (v) => setState(
                      () => _filter = StudentFilter(
                        query: _filter.query,
                        gradeId: _filter.gradeId,
                        groupId: v,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: rows.isEmpty
                  ? const EmptyState(icon: Icons.search_off, title: 'لا يوجد طلاب مطابقون')
                  : ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, i) {
                        final r = rows[i];
                        return ListTile(
                          selected: r.student.id == _selectedId,
                          leading: CircleAvatar(child: Text(r.student.name.characters.first)),
                          title: Text(r.student.name),
                          subtitle: Text('${r.grade.name} – ${GroupLabels.name(r.group.number)}'),
                          trailing: StatusChip.payment(r.billing.status),
                          onTap: () {
                            setState(() => _selectedId = r.student.id);
                            if (!wide) _openSheet(r);
                          },
                        );
                      },
                    ),
            ),
          ],
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 760) return picker(wide: false);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 400, child: picker(wide: true)),
                const VerticalDivider(width: 1),
                Expanded(
                  child: selected == null
                      ? const EmptyState(
                          icon: Icons.payments_outlined,
                          title: 'اختر طالباً لتسجيل الدفع',
                          message: 'السعر يظهر تلقائياً حسب مجموعة الطالب والخصم.',
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 560),
                              child: PaymentForm(key: ValueKey(selected.student.id), row: selected),
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
