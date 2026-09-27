import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/models.dart';
import '../data/repository_providers.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Who is signed in and which tenant / student the screens are currently scoped to.
class Session {
  const Session({required this.user, this.tenantId, this.activeStudentId});

  final User user;

  /// Current tenant: the teacher's own, the assistant's employer, or the
  /// student/parent's selected teacher. Null for platform admin or a student
  /// without enrollments yet.
  final String? tenantId;

  /// The student whose data student/parent screens show (self or selected child).
  final String? activeStudentId;

  UserRole get role => user.role;

  Session copyWith({String? tenantId, String? activeStudentId}) => Session(
    user: user,
    tenantId: tenantId ?? this.tenantId,
    activeStudentId: activeStudentId ?? this.activeStudentId,
  );
}

class SessionController extends Notifier<Session?> {
  @override
  Session? build() => null;

  Future<void> signIn({required String phone, required String password}) async {
    final user = await ref
        .read(authRepositoryProvider)
        .signIn(phone: phone.trim(), password: password);
    if (user == null) throw const AuthFailure('رقم الموبايل أو كلمة المرور غير صحيحة');
    state = await _resolve(user);
  }

  void signOut() => state = null;

  /// Parent only: switch the child shown on parent screens.
  Future<void> selectChild(String studentId) async {
    final current = state;
    if (current == null || current.role != UserRole.parent) return;
    final tenantId = await _firstTenantOf(studentId);
    state = Session(user: current.user, tenantId: tenantId, activeStudentId: studentId);
  }

  /// Student / parent: switch between the teachers the student is enrolled with.
  void selectTenant(String tenantId) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(tenantId: tenantId);
  }

  Future<Session> _resolve(User user) async {
    switch (user.role) {
      case UserRole.platformAdmin:
        return Session(user: user);
      case UserRole.teacher:
        final tenant = await ref.read(tenantRepositoryProvider).getByOwner(user.id);
        if (tenant == null) throw const AuthFailure('لا يوجد حساب مدرس مرتبط بهذا المستخدم');
        return Session(user: user, tenantId: tenant.id);
      case UserRole.assistant:
        final memberships = await ref.read(staffRepositoryProvider).getForUser(user.id);
        if (memberships.isEmpty) throw const AuthFailure('هذا الحساب غير مضاف لأي مدرس');
        return Session(user: user, tenantId: memberships.first.tenantId);
      case UserRole.student:
        return Session(
          user: user,
          tenantId: await _firstTenantOf(user.id),
          activeStudentId: user.id,
        );
      case UserRole.parent:
        final links = await ref.read(studentRepositoryProvider).getLinksForParent(user.id);
        if (links.isEmpty) return Session(user: user);
        final childId = links.first.studentUserId;
        return Session(
          user: user,
          tenantId: await _firstTenantOf(childId),
          activeStudentId: childId,
        );
    }
  }

  Future<String?> _firstTenantOf(String studentId) async {
    final enrollments = await ref.read(enrollmentRepositoryProvider).getForStudent(studentId);
    final active = enrollments.where((e) => e.active);
    return active.isEmpty ? null : active.first.tenantId;
  }
}

final sessionProvider = NotifierProvider<SessionController, Session?>(SessionController.new);

/// Live tenant of the session (settings edits propagate to every screen).
final currentTenantProvider = StreamProvider<Tenant?>((ref) {
  final tenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
  if (tenantId == null) return Stream.value(null);
  return ref.watch(tenantRepositoryProvider).watchById(tenantId);
});

/// Live staff membership of the signed-in assistant (permission changes apply immediately).
final currentStaffProvider = StreamProvider<StaffMember?>((ref) {
  final session = ref.watch(sessionProvider);
  if (session == null || session.role != UserRole.assistant || session.tenantId == null) {
    return Stream.value(null);
  }
  return ref
      .watch(staffRepositoryProvider)
      .watchByTenant(session.tenantId!)
      .map((staff) => staff.where((s) => s.userId == session.user.id).firstOrNull);
});
