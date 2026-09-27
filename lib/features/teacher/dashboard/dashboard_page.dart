import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/status_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../services/payment_status_service.dart';
import 'dashboard_charts.dart';
import 'dashboard_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueView(
      value: ref.watch(dashboardProvider),
      builder: (data) => PageContainer(
        children: [
          _StatGrid(data: data),
          const SizedBox(height: 16),
          SectionCard(
            title: 'نسبة الحضور – آخر 30 يوم',
            subtitle: 'الحاضرون والمتأخرون من إجمالي المسجلين في كل يوم حصص',
            child: SizedBox(height: 220, child: AttendanceLineChart(days: data.dailyAttendance)),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final charts = [
                SectionCard(
                  title: 'الدخل والمصروفات',
                  subtitle: 'آخر 6 شهور (الاشتراكات + المذكرات)',
                  child: SizedBox(height: 260, child: IncomeExpenseChart(months: data.months)),
                ),
                SectionCard(
                  title: 'حالة الدفع حسب الصف',
                  subtitle: 'اشتراكات الشهر الحالي',
                  child: SizedBox(
                    height: 260,
                    child: PaymentStatusByGradeChart(grades: data.byGrade),
                  ),
                ),
              ];
              if (constraints.maxWidth < 900) {
                return Column(children: [charts[0], const SizedBox(height: 16), charts[1]]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: charts[0]),
                  const SizedBox(width: 16),
                  Expanded(child: charts[1]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);
    final counts = data.statusCounts;
    final paid = counts[PaymentStatus.paid] ?? 0;
    final unpaid = (counts[PaymentStatus.due] ?? 0) + (counts[PaymentStatus.overdue] ?? 0);
    final month = data.currentMonth;

    final cards = [
      StatCard(
        label: 'الطلاب',
        value: '${data.activeStudents}',
        icon: Icons.groups_outlined,
        caption: 'طالب مسجل حالياً',
      ),
      StatCard(
        label: 'المجموعات',
        value: '${data.groups}',
        icon: Icons.calendar_view_week_outlined,
        caption: 'منها ${data.privateGroups} خاصة',
      ),
      StatCard(
        label: 'حضور اليوم',
        value: '${data.today.attended} / ${data.today.expected}',
        icon: Icons.fact_check_outlined,
        caption: data.today.expected == 0 ? 'لا توجد حصص اليوم' : 'من المتوقع حضورهم اليوم',
      ),
      StatCard(
        label: 'مدفوع / غير مدفوع',
        value: '$paid / $unpaid',
        icon: Icons.receipt_long_outlined,
        accent: (counts[PaymentStatus.overdue] ?? 0) > 0 ? status.danger : status.success,
        caption: 'منهم ${counts[PaymentStatus.overdue] ?? 0} متأخر',
      ),
      StatCard(
        label: 'دخل الشهر',
        value: Money.format(month.income),
        icon: Icons.account_balance_wallet_outlined,
        caption: 'مذكرات ${Money.format(month.sheetsIncome)}',
      ),
      StatCard(
        label: 'صافي الشهر',
        value: Money.format(month.net),
        icon: Icons.trending_up,
        accent: month.net >= 0 ? status.success : status.danger,
        caption: 'مصروفات ${Money.format(month.expenses)}',
      ),
    ];

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        mainAxisExtent: 100,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      children: cards,
    );
  }
}
