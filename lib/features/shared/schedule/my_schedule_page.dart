import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/labels.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/models.dart';
import '../../../services/student_context.dart';
import '../../../services/tenant_data.dart';

/// The active student's weekly sessions (their own group(s) in the current tenant).
class MySchedulePage extends ConsumerWidget {
  const MySchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(activeStudentGroupsProvider);
    final gradeNames = {
      for (final g in ref.watch(gradesProvider).asData?.value ?? const <Grade>[]) g.id: g.name,
    };

    final rows =
        <(int weekday, GroupSession session, Group group)>[
          for (final g in groups)
            for (final s in g.sessions) (s.weekday, s, g),
        ]..sort((a, b) {
          final byDay = AppDates.weekOrder
              .indexOf(a.$1)
              .compareTo(AppDates.weekOrder.indexOf(b.$1));
          return byDay != 0 ? byDay : a.$2.startTime.compareTo(b.$2.startTime);
        });

    if (rows.isEmpty) {
      return const EmptyState(icon: Icons.calendar_month_outlined, title: 'لا يوجد جدول حصص بعد');
    }

    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final (weekday, session, group) = rows[i];
        final color = group.isPrivate ? AppTheme.privateGroupColor : theme.colorScheme.primary;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Text(
                AppDates.weekdayName(weekday).characters.first,
                style: TextStyle(color: color),
              ),
            ),
            title: Text(AppDates.weekdayName(weekday), style: theme.textTheme.titleSmall),
            subtitle: Text(
              '${gradeNames[group.gradeId] ?? ''} – ${GroupLabels.name(group.number)}'
              '${group.address == null ? '' : ' • ${group.address}'}',
            ),
            trailing: Text(
              '${AppDates.clock(session.startTime)} – ${AppDates.clock(session.endTime)}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        );
      },
    );
  }
}
