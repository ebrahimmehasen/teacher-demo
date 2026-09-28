import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/labels.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/models.dart';
import '../../../services/student_lookup.dart';
import '../../../services/tenant_data.dart';

Future<void> showStudentDetailSheet(BuildContext context, StudentRowLike row) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => _StudentDetailSheet(row: row),
    );

/// The minimum a caller needs to identify a student for the detail sheet.
class StudentRowLike {
  const StudentRowLike({
    required this.studentId,
    required this.name,
    required this.phone,
    required this.groupLabel,
  });

  final String studentId;
  final String name;
  final String phone;
  final String groupLabel;
}

class _StudentDetailSheet extends ConsumerWidget {
  const _StudentDetailSheet({required this.row});
  final StudentRowLike row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final attendance =
        ref.watch(studentAttendanceProvider(row.studentId)).asData?.value ?? const <Attendance>[];
    final results =
        ref.watch(studentResultsProvider(row.studentId)).asData?.value ??
        const <AssessmentResult>[];
    final payments =
        ref.watch(studentPaymentsProvider(row.studentId)).asData?.value ?? const <Payment>[];
    final complaints =
        ref.watch(studentComplaintsProvider(row.studentId)).asData?.value ?? const <Complaint>[];
    final assessments = {
      for (final a in ref.watch(assessmentsProvider).asData?.value ?? const <Assessment>[]) a.id: a,
    };

    final sortedAttendance = [...attendance]..sort((a, b) => b.date.compareTo(a.date));
    final sortedPayments = [...payments]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final sortedComplaints = [...complaints]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final gradedResults = [
      for (final r in results)
        if (assessments[r.assessmentId] case final a?) (a, r),
    ]..sort((a, b) => b.$1.date.compareTo(a.$1.date));

    final now = ref.watch(clockProvider)();
    final thisMonth = attendance.where((a) => a.date.year == now.year && a.date.month == now.month);
    final present = thisMonth
        .where((a) => a.status == AttendanceStatus.present || a.status == AttendanceStatus.late)
        .length;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Row(
            children: [
              CircleAvatar(radius: 28, child: Text(row.name.characters.first)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.name,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(row.groupLabel, style: theme.textTheme.bodyMedium),
                    Text(
                      row.phone,
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'حضر $present من ${thisMonth.length} حصة هذا الشهر',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const Divider(height: 32),

          Text('الحضور', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (sortedAttendance.isEmpty)
            const Text('لا يوجد سجل حضور بعد.')
          else
            for (final a in sortedAttendance.take(10))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(AppDates.dayMonth(a.date)),
                subtitle: a.status == AttendanceStatus.late
                    ? Text('تأخير ${a.lateMinutes} دقيقة')
                    : a.excuseText != null
                    ? Text('العذر: ${a.excuseText}')
                    : null,
                trailing: StatusChip.attendance(a.status),
              ),
          const Divider(height: 32),

          Text(
            'المدفوعات',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (sortedPayments.isEmpty)
            const Text('لا توجد مدفوعات مسجلة.')
          else
            for (final p in sortedPayments.take(8))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(
                  '${Money.format(p.amount)} – ${AppDates.monthYear(AppDates.parseMonthKey(p.month))}',
                ),
                subtitle: Text('${p.method.label} • ${AppDates.short(p.createdAt)}'),
              ),
          const Divider(height: 32),

          Text(
            'الدرجات والواجبات',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (gradedResults.isEmpty)
            const Text('لا توجد نتائج بعد.')
          else
            for (final (assessment, result) in gradedResults.take(10))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(assessment.title),
                subtitle: Text('${assessment.type.label} • ${AppDates.dayMonth(assessment.date)}'),
                trailing: assessment.maxScore == null
                    ? Icon(result.delivered ? Icons.check_circle : Icons.cancel)
                    : Text(
                        result.score == null
                            ? '—'
                            : '${result.score} / ${assessment.maxScore!.toStringAsFixed(0)}',
                      ),
              ),
          const Divider(height: 32),

          Text(
            'الشكاوى والتنبيهات',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (sortedComplaints.isEmpty)
            const Text('لا توجد شكاوى أو تنبيهات.')
          else
            for (final c in sortedComplaints)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  c.kind == ComplaintKind.warning
                      ? Icons.warning_amber_outlined
                      : Icons.report_outlined,
                ),
                title: Text(c.text),
                subtitle: Text('${c.kind.label} • ${AppDates.dayMonth(c.createdAt)}'),
              ),
        ],
      ),
    );
  }
}
