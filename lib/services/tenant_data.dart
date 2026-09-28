import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/labels.dart';
import '../core/utils/date_utils.dart';
import '../data/models/models.dart';
import '../data/repository_providers.dart';
import 'dashboard_service.dart';
import 'payment_status_service.dart';
import 'session_service.dart';

/// Overridable in tests to freeze "now".
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

Stream<List<T>> _scoped<T>(String? tenantId, Stream<List<T>> Function(String tenantId) watch) =>
    tenantId == null ? Stream.value(<T>[]) : watch(tenantId);

final allTenantsProvider = StreamProvider<List<Tenant>>(
  (ref) => ref.watch(tenantRepositoryProvider).watchAll(),
);

final gradesProvider = StreamProvider<List<Grade>>((ref) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  return _scoped(tenantId, ref.watch(gradeRepositoryProvider).watchByTenant);
});

final groupsProvider = StreamProvider<List<Group>>((ref) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  return _scoped(tenantId, ref.watch(groupRepositoryProvider).watchByTenant);
});

final periodsProvider = StreamProvider<SchedulePeriods?>((ref) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  if (tenantId == null) return Stream.value(null);
  return ref.watch(groupRepositoryProvider).watchPeriods(tenantId);
});

final enrollmentsProvider = StreamProvider<List<Enrollment>>((ref) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  return _scoped(tenantId, ref.watch(enrollmentRepositoryProvider).watchByTenant);
});

final paymentsProvider = StreamProvider<List<Payment>>((ref) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  return _scoped(tenantId, (id) => ref.watch(paymentRepositoryProvider).watchByTenant(id));
});

final expensesProvider = StreamProvider<List<Expense>>((ref) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  return _scoped(tenantId, ref.watch(expenseRepositoryProvider).watchByTenant);
});

final sheetSalesProvider = StreamProvider<List<SheetSale>>((ref) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  return _scoped(tenantId, ref.watch(sheetRepositoryProvider).watchSales);
});

final sheetsProvider = StreamProvider<List<Sheet>>((ref) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  return _scoped(tenantId, ref.watch(sheetRepositoryProvider).watchSheets);
});

final lessonsProvider = StreamProvider<List<RecordedLesson>>((ref) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  return _scoped(tenantId, ref.watch(lessonRepositoryProvider).watchByTenant);
});

final announcementsProvider = StreamProvider<List<Announcement>>((ref) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  return _scoped(tenantId, ref.watch(announcementRepositoryProvider).watchByTenant);
});

final assessmentsProvider = StreamProvider<List<Assessment>>((ref) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  return _scoped(tenantId, ref.watch(assessmentRepositoryProvider).watchAssessments);
});

final assessmentResultsProvider = StreamProvider<List<AssessmentResult>>((ref) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  return _scoped(tenantId, (id) => ref.watch(assessmentRepositoryProvider).watchResults(id));
});

/// "تالتة ثانوي – المجموعة الأولى" by group id.
final groupLabelsProvider = Provider<Map<String, String>>((ref) {
  final grades = {
    for (final g in ref.watch(gradesProvider).asData?.value ?? const <Grade>[]) g.id: g.name,
  };
  return {
    for (final g in ref.watch(groupsProvider).asData?.value ?? const <Group>[])
      g.id: '${grades[g.gradeId] ?? ''} – ${GroupLabels.name(g.number)}',
  };
});

/// Attendance of the last 60 days (enough for dashboards and monthly views).
final recentAttendanceProvider = StreamProvider<List<Attendance>>((ref) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  final today = AppDates.dateOnly(ref.watch(clockProvider)());
  return _scoped(
    tenantId,
    (id) => ref
        .watch(attendanceRepositoryProvider)
        .watchByTenant(id, from: today.subtract(const Duration(days: 60))),
  );
});

/// Enrolled students of the tenant, by user id.
final tenantStudentsProvider = StreamProvider<Map<String, User>>((ref) async* {
  final enrollments = await ref.watch(enrollmentsProvider.future);
  final ids = {for (final e in enrollments) e.studentId};
  yield* ref
      .watch(userRepositoryProvider)
      .watchByIds(ids)
      .map((users) => {for (final u in users) u.id: u});
});

/// Billing of every active enrollment for the current month.
final currentBillingProvider = FutureProvider<List<Billing>>((ref) async {
  final now = ref.watch(clockProvider)();
  return DashboardService.billing(
    month: AppDates.monthKey(now),
    today: now,
    enrollments: await ref.watch(enrollmentsProvider.future),
    groups: await ref.watch(groupsProvider.future),
    grades: await ref.watch(gradesProvider.future),
    payments: await ref.watch(paymentsProvider.future),
  );
});

/// Creates overdue reminders (rule 2) for the current and previous month.
/// Stand-in for a backend scheduled job; reminders are idempotent by id.
final overdueRemindersProvider = FutureProvider<int>((ref) async {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  if (tenantId == null) return 0;
  final now = ref.watch(clockProvider)();
  final enrollments = await ref.watch(enrollmentsProvider.future);
  final groups = await ref.watch(groupsProvider.future);
  final grades = await ref.watch(gradesProvider.future);
  final payments = await ref.watch(paymentsProvider.future);
  final students = await ref.watch(tenantStudentsProvider.future);

  final overdue = <(String month, Billing billing)>[
    for (final offset in [-1, 0])
      for (final b in DashboardService.billing(
        month: AppDates.monthKey(AppDates.addMonths(now, offset)),
        today: now,
        enrollments: enrollments,
        groups: groups,
        grades: grades,
        payments: payments,
      ))
        if (b.status == PaymentStatus.overdue)
          (AppDates.monthKey(AppDates.addMonths(now, offset)), b),
  ];
  if (overdue.isEmpty) return 0;

  final links = await ref.read(studentRepositoryProvider).watchLinksForStudents({
    for (final (_, b) in overdue) b.enrollment.studentId,
  }).first;

  final notifications = [
    for (final (month, b) in overdue)
      ...PaymentStatusService.overdueNotifications(
        tenantId: tenantId,
        studentId: b.enrollment.studentId,
        studentName: students[b.enrollment.studentId]?.name ?? '',
        month: month,
        amountDue: b.price - b.paid,
        parentIds: links
            .where((l) => l.studentUserId == b.enrollment.studentId)
            .map((l) => l.parentUserId),
        now: now,
      ),
  ];
  await ref.read(notificationRepositoryProvider).addAll(notifications);
  return notifications.length;
});
