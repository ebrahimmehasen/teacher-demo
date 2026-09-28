import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/enums.dart';
import '../../../services/student_context.dart';
import '../../../services/tenant_data.dart';

/// Attendance table for the active student: date, status, late minutes, excuse.
class MyAttendancePage extends ConsumerWidget {
  const MyAttendancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = ref.watch(groupLabelsProvider);
    return AsyncValueView(
      value: ref.watch(activeStudentAttendanceProvider),
      builder: (records) {
        if (records.isEmpty) {
          return const EmptyState(icon: Icons.fact_check_outlined, title: 'لا يوجد سجل حضور بعد');
        }
        final sorted = [...records]..sort((a, b) => b.date.compareTo(a.date));
        final theme = Theme.of(context);
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sorted.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final a = sorted[i];
            final details = [
              labels[a.groupId] ?? '',
              if (a.status == AttendanceStatus.late) 'تأخير ${a.lateMinutes} دقيقة',
              if (a.isMakeup) 'حصة تعويض',
              if (a.excuseText != null) 'العذر: ${a.excuseText}',
            ].join(' • ');
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${a.date.day}')),
                title: Text(AppDates.dayMonth(a.date), style: theme.textTheme.titleSmall),
                subtitle: Text(details),
                trailing: StatusChip.attendance(a.status),
              ),
            );
          },
        );
      },
    );
  }
}
