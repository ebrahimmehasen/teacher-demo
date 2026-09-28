import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/models.dart';
import '../../../services/session_service.dart';
import '../../../services/student_context.dart';
import '../../../services/tenant_data.dart';

class StudentHomePage extends ConsumerWidget {
  const StudentHomePage({super.key});

  static const _tiles = [
    (Icons.qr_code_2, 'مسح QR', '/student/qr'),
    (Icons.calendar_month_outlined, 'الجدول', '/student/schedule'),
    (Icons.fact_check_outlined, 'الحضور', '/student/more/attendance'),
    (Icons.assignment_outlined, 'الدرجات والواجبات', '/student/more/grades'),
    (Icons.mail_outline, 'الطلبات', '/student/requests'),
    (Icons.video_library_outlined, 'الحصص المسجلة', '/student/more/lessons'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(sessionProvider);
    final now = ref.watch(clockProvider)();
    final today = AppDates.dateOnly(now);

    final groups = ref.watch(activeStudentGroupsProvider);
    final hasSessionToday = groups.any((g) => g.sessions.any((s) => s.weekday == today.weekday));
    final attendanceToday =
        (ref.watch(activeStudentAttendanceProvider).asData?.value ?? const <Attendance>[])
            .where((a) => AppDates.dateOnly(a.date) == today)
            .toList();

    final myGradeIds = {for (final g in ref.watch(activeStudentGradesProvider)) g.id};
    final announcements = ref.watch(announcementsProvider).asData?.value ?? const <Announcement>[];
    final visibleAnnouncements =
        announcements.where((a) => a.isForAll || myGradeIds.contains(a.gradeId)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final latest = visibleAnnouncements.firstOrNull;

    return PageContainer(
      maxWidth: 800,
      children: [
        Text(
          'أهلاً ${session?.user.name ?? ''}',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(AppDates.dayMonth(today), style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        SectionCard(
          title: 'اليوم',
          child: !hasSessionToday
              ? const Text('لا توجد حصة لك اليوم.')
              : attendanceToday.isEmpty
              ? const Text('لم يتم تسجيل حضورك اليوم بعد.')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final a in attendanceToday) StatusChip.attendance(a.status)],
                ),
        ),
        if (latest != null) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: 'آخر إعلان',
            subtitle: AppDates.dayMonth(latest.createdAt),
            trailing: TextButton(
              onPressed: () => context.go('/student/more/announcements'),
              child: const Text('عرض الكل'),
            ),
            child: Text(latest.body, maxLines: 3, overflow: TextOverflow.ellipsis),
          ),
        ],
        const SizedBox(height: 16),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            mainAxisExtent: 96,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          children: [
            for (final (icon, label, path) in _tiles)
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.go(path),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: theme.colorScheme.primary, size: 28),
                      const SizedBox(height: 8),
                      Text(label, style: theme.textTheme.titleSmall, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
