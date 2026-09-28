import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/models.dart';
import '../data/repository_providers.dart';
import 'session_service.dart';

/// Watchers for an arbitrary student's data within the current tenant, keyed
/// by an explicit id (unlike `activeStudent*`, which follows the session).
/// Used by the teacher's student-detail sheet.
final studentAttendanceProvider = StreamProvider.family<List<Attendance>, String>((ref, studentId) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  if (tenantId == null) return Stream.value(const []);
  return ref.watch(attendanceRepositoryProvider).watchByTenant(tenantId, studentId: studentId);
});

final studentResultsProvider = StreamProvider.family<List<AssessmentResult>, String>((
  ref,
  studentId,
) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  if (tenantId == null) return Stream.value(const []);
  return ref.watch(assessmentRepositoryProvider).watchResults(tenantId, studentId: studentId);
});

final studentPaymentsProvider = StreamProvider.family<List<Payment>, String>((ref, studentId) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  if (tenantId == null) return Stream.value(const []);
  return ref.watch(paymentRepositoryProvider).watchByTenant(tenantId, studentId: studentId);
});

final studentComplaintsProvider = StreamProvider.family<List<Complaint>, String>((ref, studentId) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  if (tenantId == null) return Stream.value(const []);
  return ref.watch(complaintRepositoryProvider).watchByTenant(tenantId, studentId: studentId);
});

final studentRequestsProvider = StreamProvider.family<List<Request>, String>((ref, studentId) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  if (tenantId == null) return Stream.value(const []);
  return ref.watch(requestRepositoryProvider).watchByTenant(tenantId, studentId: studentId);
});
