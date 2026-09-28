import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_container.dart';
import '../../../services/parent_context.dart';
import '../../../services/session_service.dart';
import '../../../services/student_context.dart';
import '../../../services/tenant_data.dart';
import '../../shared/home/latest_announcement_card.dart';
import '../../shared/home/payment_status_card.dart';
import '../../shared/home/today_status_card.dart';

class ParentHomePage extends ConsumerWidget {
  const ParentHomePage({super.key});

  static const _tiles = [
    (Icons.calendar_month_outlined, 'الجدول', '/parent/more/schedule'),
    (Icons.bar_chart_outlined, 'التقرير', '/parent/more/report'),
    (Icons.receipt_long_outlined, 'المدفوعات', '/parent/more/payments'),
    (Icons.video_library_outlined, 'الحصص المسجلة', '/parent/more/lessons'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(sessionProvider);
    final today = AppDates.dateOnly(ref.watch(clockProvider)());
    final children = ref.watch(parentChildrenProvider).asData?.value;
    final activeChild = ref.watch(activeStudentProvider).asData?.value;

    if (children != null && children.isEmpty) {
      return EmptyState(
        icon: Icons.family_restroom,
        title: 'لا يوجد أبناء مرتبطون بعد',
        message: 'اطلب كود الربط من صفحة الملف الشخصي في تطبيق ابنك/ابنتك.',
        action: FilledButton.icon(
          onPressed: () => context.go('/parent/more/children'),
          icon: const Icon(Icons.add),
          label: const Text('إضافة طفل'),
        ),
      );
    }

    return PageContainer(
      maxWidth: 800,
      children: [
        Text(
          'أهلاً ${session?.user.name ?? ''}',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          activeChild == null
              ? AppDates.dayMonth(today)
              : '${activeChild.name} • ${AppDates.dayMonth(today)}',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        const TodayStatusCard(),
        const SizedBox(height: 16),
        const PaymentStatusCard(),
        const SizedBox(height: 16),
        const LatestAnnouncementCard(seeAllPath: '/parent/more/announcements'),
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
