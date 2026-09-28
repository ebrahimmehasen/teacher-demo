import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/date_utils.dart';
import '../data/models/models.dart';
import '../data/repository_providers.dart';
import 'dashboard_service.dart';
import 'payment_status_service.dart';
import 'pricing_service.dart';
import 'session_service.dart';
import 'tenant_data.dart';

/// The student whose data the screens show: the signed-in student themselves,
/// or the parent's selected child. Shared by student and parent screens so the
/// same widgets work for both roles unchanged.
final activeStudentIdProvider = Provider<String?>(
  (ref) => ref.watch(sessionProvider.select((s) => s?.activeStudentId)),
);

final activeStudentProvider = StreamProvider<User?>((ref) {
  final id = ref.watch(activeStudentIdProvider);
  if (id == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchByIds({id}).map((users) => users.firstOrNull);
});

final activeStudentProfileProvider = StreamProvider<StudentProfile?>((ref) {
  final id = ref.watch(activeStudentIdProvider);
  if (id == null) return Stream.value(null);
  return ref
      .watch(studentRepositoryProvider)
      .watchProfiles({id})
      .map((profiles) => profiles.firstOrNull);
});

/// Every tenant the active student is enrolled with (drives the teacher/subject switcher).
final activeStudentEnrollmentsProvider = StreamProvider<List<Enrollment>>((ref) {
  final id = ref.watch(activeStudentIdProvider);
  if (id == null) return Stream.value(const []);
  return ref.watch(enrollmentRepositoryProvider).watchForStudent(id);
});

/// Active enrollments of the student in the *current* tenant (normally exactly one).
final activeStudentTenantEnrollmentsProvider = Provider<List<Enrollment>>((ref) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  final all = ref.watch(activeStudentEnrollmentsProvider).asData?.value ?? const <Enrollment>[];
  return [
    for (final e in all)
      if (e.active && e.tenantId == tenantId) e,
  ];
});

/// The groups the active student currently attends in this tenant.
final activeStudentGroupsProvider = Provider<List<Group>>((ref) {
  final groupIds = {for (final e in ref.watch(activeStudentTenantEnrollmentsProvider)) e.groupId};
  final groups = ref.watch(groupsProvider).asData?.value ?? const <Group>[];
  return [
    for (final g in groups)
      if (groupIds.contains(g.id)) g,
  ];
});

/// The grade(s) of the active student's current groups (normally exactly one).
final activeStudentGradesProvider = Provider<List<Grade>>((ref) {
  final gradeIds = {for (final g in ref.watch(activeStudentGroupsProvider)) g.gradeId};
  final grades = ref.watch(gradesProvider).asData?.value ?? const <Grade>[];
  return [
    for (final g in grades)
      if (gradeIds.contains(g.id)) g,
  ];
});

/// Current-month billing of the active student's current-tenant enrollment(s).
/// Empty when the student isn't enrolled in the current tenant (e.g. a
/// platform admin, or a parent with no child selected yet).
final activeStudentBillingProvider = FutureProvider<List<Billing>>((ref) async {
  final now = ref.watch(clockProvider)();
  final enrollments = ref.watch(activeStudentTenantEnrollmentsProvider);
  if (enrollments.isEmpty) return const [];
  final groups = {
    for (final g in ref.watch(groupsProvider).asData?.value ?? const <Group>[]) g.id: g,
  };
  final grades = {
    for (final g in ref.watch(gradesProvider).asData?.value ?? const <Grade>[]) g.id: g,
  };
  final payments = await ref.watch(paymentsProvider.future);

  return [
    for (final e in enrollments)
      if (groups[e.groupId] case final group?)
        if (grades[group.gradeId] case final grade?)
          Billing(
            enrollment: e,
            group: group,
            grade: grade,
            price: PricingService.monthlyPrice(enrollment: e, group: group, grade: grade),
            paid: PaymentStatusService.paidAmount(payments, e.studentId, AppDates.monthKey(now)),
            status: PaymentStatusService.statusFor(
              enrollment: e,
              grade: grade,
              price: PricingService.monthlyPrice(enrollment: e, group: group, grade: grade),
              month: AppDates.monthKey(now),
              payments: payments,
              today: now,
            ),
          ),
  ];
});

final activeStudentPaymentsProvider = StreamProvider<List<Payment>>((ref) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  final studentId = ref.watch(activeStudentIdProvider);
  if (tenantId == null || studentId == null) return Stream.value(const []);
  return ref.watch(paymentRepositoryProvider).watchByTenant(tenantId, studentId: studentId);
});

final activeStudentAttendanceProvider = StreamProvider<List<Attendance>>((ref) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  final studentId = ref.watch(activeStudentIdProvider);
  if (tenantId == null || studentId == null) return Stream.value(const []);
  return ref.watch(attendanceRepositoryProvider).watchByTenant(tenantId, studentId: studentId);
});

final activeStudentResultsProvider = StreamProvider<List<AssessmentResult>>((ref) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  final studentId = ref.watch(activeStudentIdProvider);
  if (tenantId == null || studentId == null) return Stream.value(const []);
  return ref.watch(assessmentRepositoryProvider).watchResults(tenantId, studentId: studentId);
});

final activeStudentRequestsProvider = StreamProvider<List<Request>>((ref) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  final studentId = ref.watch(activeStudentIdProvider);
  if (tenantId == null || studentId == null) return Stream.value(const []);
  return ref.watch(requestRepositoryProvider).watchByTenant(tenantId, studentId: studentId);
});

final activeStudentComplaintsProvider = StreamProvider<List<Complaint>>((ref) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  final studentId = ref.watch(activeStudentIdProvider);
  if (tenantId == null || studentId == null) return Stream.value(const []);
  return ref.watch(complaintRepositoryProvider).watchByTenant(tenantId, studentId: studentId);
});
