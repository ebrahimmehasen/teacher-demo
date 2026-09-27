import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart';
import '../../../data/models/models.dart';
import '../../../services/accounts_service.dart';
import '../../../services/dashboard_service.dart';
import '../../../services/payment_status_service.dart';
import '../../../services/tenant_data.dart';

class GradePaymentStatus {
  const GradePaymentStatus(this.grade, this.counts);
  final Grade grade;
  final Map<PaymentStatus, int> counts;
}

class DashboardData {
  const DashboardData({
    required this.activeStudents,
    required this.groups,
    required this.privateGroups,
    required this.today,
    required this.statusCounts,
    required this.dailyAttendance,
    required this.months,
    required this.byGrade,
  });

  final int activeStudents;
  final int groups;
  final int privateGroups;
  final TodayAttendance today;
  final Map<PaymentStatus, int> statusCounts;
  final List<DailyAttendance> dailyAttendance;

  /// Last 6 months, oldest first; the last one is the current month.
  final List<MonthSummary> months;
  final List<GradePaymentStatus> byGrade;

  MonthSummary get currentMonth => months.last;
}

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final now = ref.watch(clockProvider)();
  final today = AppDates.dateOnly(now);
  final enrollments = await ref.watch(enrollmentsProvider.future);
  final groups = await ref.watch(groupsProvider.future);
  final grades = await ref.watch(gradesProvider.future);
  final attendance = await ref.watch(recentAttendanceProvider.future);
  final billing = await ref.watch(currentBillingProvider.future);
  final payments = await ref.watch(paymentsProvider.future);
  final sales = await ref.watch(sheetSalesProvider.future);
  final expenses = await ref.watch(expensesProvider.future);

  return DashboardData(
    activeStudents: enrollments.where((e) => e.active).length,
    groups: groups.length,
    privateGroups: groups.where((g) => g.isPrivate).length,
    today: DashboardService.today(
      today: today,
      groups: groups,
      enrollments: enrollments,
      attendance: attendance,
    ),
    statusCounts: DashboardService.countByStatus(billing),
    dailyAttendance: DashboardService.dailyAttendance(
      attendance,
      from: today.subtract(const Duration(days: 30)),
      to: today,
    ),
    months: AccountsService.lastMonths(
      today,
      6,
      payments: payments,
      sales: sales,
      expenses: expenses,
    ),
    byGrade: [
      for (final grade in grades)
        GradePaymentStatus(
          grade,
          DashboardService.countByStatus(billing.where((b) => b.grade.id == grade.id)),
        ),
    ],
  );
});
