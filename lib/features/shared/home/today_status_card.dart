import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/models.dart';
import '../../../services/student_context.dart';
import '../../../services/tenant_data.dart';

/// "Does the active student have a session today, and did they attend it?"
class TodayStatusCard extends ConsumerWidget {
  const TodayStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = AppDates.dateOnly(ref.watch(clockProvider)());
    final groups = ref.watch(activeStudentGroupsProvider);
    final hasSessionToday = groups.any((g) => g.sessions.any((s) => s.weekday == today.weekday));
    final attendanceToday =
        (ref.watch(activeStudentAttendanceProvider).asData?.value ?? const <Attendance>[])
            .where((a) => AppDates.dateOnly(a.date) == today)
            .toList();

    return SectionCard(
      title: 'اليوم',
      child: !hasSessionToday
          ? const Text('لا توجد حصة اليوم.')
          : attendanceToday.isEmpty
          ? const Text('لم يتم تسجيل الحضور اليوم بعد.')
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final a in attendanceToday) StatusChip.attendance(a.status)],
            ),
    );
  }
}
