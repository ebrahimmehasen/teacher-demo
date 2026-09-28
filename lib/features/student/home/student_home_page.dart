import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/page_container.dart';
import '../../../services/session_service.dart';
import '../../../services/tenant_data.dart';
import '../../shared/home/latest_announcement_card.dart';
import '../../shared/home/today_status_card.dart';

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
    final today = AppDates.dateOnly(ref.watch(clockProvider)());

    return PageContainer(
      maxWidth: 800,
      children: [
        Text(
          'أهلاً ${session?.user.name ?? ''}',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(AppDates.dayMonth(today), style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        const TodayStatusCard(),
        const SizedBox(height: 16),
        const LatestAnnouncementCard(seeAllPath: '/student/more/announcements'),
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
