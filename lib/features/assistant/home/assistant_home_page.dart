import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/role_destinations.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/section_card.dart';
import '../../../data/models/models.dart';
import '../../../services/group_service.dart';
import '../../../services/session_service.dart';
import '../../../services/tenant_data.dart';
import '../../shared/attendance/attendance_log_page.dart';

class AssistantHomePage extends ConsumerWidget {
  const AssistantHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(sessionProvider);
    final staff = ref.watch(currentStaffProvider).asData?.value;
    final now = ref.watch(clockProvider)();
    final today = AppDates.dateOnly(now);
    final groups = ref.watch(groupsProvider).asData?.value ?? const <Group>[];
    final labels = ref.watch(groupLabelsProvider);
    final enrollments = ref.watch(enrollmentsProvider).asData?.value ?? const <Enrollment>[];
    final todayRecords =
        ref.watch(dayAttendanceProvider(today)).asData?.value ?? const <Attendance>[];
    final canScan = staff?.can(Permission.attendance) ?? false;

    final sessions = GroupService.sessionsOn(today, groups)
      ..sort((a, b) => a.$2.startTime.compareTo(b.$2.startTime));
    final actions = [
      for (final d in RoleDestinations.assistant.skip(1))
        if (d.permission == null || (staff?.can(d.permission!) ?? false)) d,
    ];

    return PageContainer(
      maxWidth: 1000,
      children: [
        Text(
          'أهلاً ${session?.user.name ?? ''}',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(AppDates.dayMonth(today), style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final d in actions)
              SizedBox(
                width: 150,
                height: 96,
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.go(d.path),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(d.icon, color: theme.colorScheme.primary, size: 28),
                        const SizedBox(height: 8),
                        Text(d.label, style: theme.textTheme.titleSmall),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'حصص اليوم',
          subtitle: sessions.isEmpty ? 'لا توجد حصص اليوم' : '${sessions.length} حصة',
          child: Column(
            children: [
              for (final (group, s) in sessions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    group.isPrivate ? Icons.location_on_outlined : Icons.groups_outlined,
                  ),
                  title: Text(labels[group.id] ?? ''),
                  subtitle: Text(
                    '${AppDates.clock(s.startTime)} – ${AppDates.clock(s.endTime)} • '
                    'حضر ${todayRecords.where((a) => a.groupId == group.id && (a.status == AttendanceStatus.present || a.status == AttendanceStatus.late)).length}'
                    ' من ${GroupService.enrolledCount(group.id, enrollments)}',
                  ),
                  trailing: canScan
                      ? FilledButton.tonalIcon(
                          onPressed: () => context.go('/assistant/scanner?group=${group.id}'),
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('مسح'),
                        )
                      : null,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
