import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mock/mock_academic_repositories.dart';
import 'mock/mock_communication_repositories.dart';
import 'mock/mock_database.dart';
import 'mock/mock_finance_repositories.dart';
import 'mock/mock_identity_repositories.dart';
import 'mock/seed_generator.dart';
import 'repositories/repositories.dart';

/// The only file that knows about the mock layer. Swapping to Supabase means
/// returning Supabase implementations from these providers.
final mockDatabaseProvider = Provider<MockDatabase>(
  (ref) => MockDatabase(SeedGenerator().generate()),
);

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => MockAuthRepository(ref.watch(mockDatabaseProvider)));
final userRepositoryProvider =
    Provider<UserRepository>((ref) => MockUserRepository(ref.watch(mockDatabaseProvider)));
final tenantRepositoryProvider =
    Provider<TenantRepository>((ref) => MockTenantRepository(ref.watch(mockDatabaseProvider)));
final staffRepositoryProvider =
    Provider<StaffRepository>((ref) => MockStaffRepository(ref.watch(mockDatabaseProvider)));
final studentRepositoryProvider =
    Provider<StudentRepository>((ref) => MockStudentRepository(ref.watch(mockDatabaseProvider)));
final gradeRepositoryProvider =
    Provider<GradeRepository>((ref) => MockGradeRepository(ref.watch(mockDatabaseProvider)));
final groupRepositoryProvider =
    Provider<GroupRepository>((ref) => MockGroupRepository(ref.watch(mockDatabaseProvider)));
final enrollmentRepositoryProvider = Provider<EnrollmentRepository>(
    (ref) => MockEnrollmentRepository(ref.watch(mockDatabaseProvider)));
final attendanceRepositoryProvider = Provider<AttendanceRepository>(
    (ref) => MockAttendanceRepository(ref.watch(mockDatabaseProvider)));
final assessmentRepositoryProvider = Provider<AssessmentRepository>(
    (ref) => MockAssessmentRepository(ref.watch(mockDatabaseProvider)));
final lessonRepositoryProvider =
    Provider<LessonRepository>((ref) => MockLessonRepository(ref.watch(mockDatabaseProvider)));
final paymentRepositoryProvider =
    Provider<PaymentRepository>((ref) => MockPaymentRepository(ref.watch(mockDatabaseProvider)));
final expenseRepositoryProvider =
    Provider<ExpenseRepository>((ref) => MockExpenseRepository(ref.watch(mockDatabaseProvider)));
final sheetRepositoryProvider =
    Provider<SheetRepository>((ref) => MockSheetRepository(ref.watch(mockDatabaseProvider)));
final requestRepositoryProvider =
    Provider<RequestRepository>((ref) => MockRequestRepository(ref.watch(mockDatabaseProvider)));
final complaintRepositoryProvider = Provider<ComplaintRepository>(
    (ref) => MockComplaintRepository(ref.watch(mockDatabaseProvider)));
final announcementRepositoryProvider = Provider<AnnouncementRepository>(
    (ref) => MockAnnouncementRepository(ref.watch(mockDatabaseProvider)));
final notificationRepositoryProvider = Provider<NotificationRepository>(
    (ref) => MockNotificationRepository(ref.watch(mockDatabaseProvider)));
