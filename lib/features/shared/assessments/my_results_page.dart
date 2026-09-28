import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/labels.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/models.dart';
import '../../../services/student_context.dart';
import '../../../services/tenant_data.dart';

/// Homework/exam results for the active student: delivered ✓/✗, score/max.
class MyResultsPage extends ConsumerWidget {
  const MyResultsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessments = {
      for (final a in ref.watch(assessmentsProvider).asData?.value ?? const <Assessment>[]) a.id: a,
    };
    return AsyncValueView(
      value: ref.watch(activeStudentResultsProvider),
      builder: (results) {
        final rows = [
          for (final r in results)
            if (assessments[r.assessmentId] case final a?) (a, r),
        ]..sort((x, y) => y.$1.date.compareTo(x.$1.date));

        if (rows.isEmpty) {
          return const EmptyState(
            icon: Icons.assignment_outlined,
            title: 'لا توجد واجبات أو امتحانات بعد',
          );
        }
        final theme = Theme.of(context);
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final (assessment, result) = rows[i];
            final isExam = assessment.type == AssessmentType.exam;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    isExam ? Icons.school_outlined : Icons.assignment_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(assessment.title),
                subtitle: Text('${assessment.type.label} • ${AppDates.dayMonth(assessment.date)}'),
                trailing: assessment.maxScore != null
                    ? Text(
                        result.score == null
                            ? '—'
                            : '${_fmt(result.score!)} / ${_fmt(assessment.maxScore!)}',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      )
                    : Icon(
                        result.delivered ? Icons.check_circle : Icons.cancel,
                        color: toneColor(
                          context,
                          result.delivered ? StatusTone.success : StatusTone.danger,
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  static String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';
}
