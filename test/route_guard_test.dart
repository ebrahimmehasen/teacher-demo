import 'package:flutter_test/flutter_test.dart';
import 'package:teacher_demo/core/router/route_guard.dart';
import 'package:teacher_demo/data/models/models.dart';
import 'package:teacher_demo/services/session_service.dart';

Session _session(UserRole role) => Session(
      user: User(id: 'u', name: 'x', phone: '01000000009', password: 'p', role: role),
      tenantId: 't',
    );

void main() {
  test('signed-out users can only see the login page', () {
    expect(resolveRedirect(session: null, staff: null, path: '/login'), isNull);
    expect(resolveRedirect(session: null, staff: null, path: '/teacher/dashboard'), '/login');
  });

  test('signed-in users are sent from login to their role home', () {
    final expected = {
      UserRole.teacher: '/teacher/dashboard',
      UserRole.assistant: '/assistant/home',
      UserRole.student: '/student/home',
      UserRole.parent: '/parent/home',
      UserRole.platformAdmin: '/admin/tenants',
    };
    for (final MapEntry(key: role, value: home) in expected.entries) {
      expect(resolveRedirect(session: _session(role), staff: null, path: '/login'), home);
    }
  });

  test("a role cannot open another role's screens", () {
    final student = _session(UserRole.student);
    expect(resolveRedirect(session: student, staff: null, path: '/teacher/accounts'),
        '/student/home');
    expect(resolveRedirect(session: student, staff: null, path: '/student/qr'), isNull);
    expect(resolveRedirect(session: student, staff: null, path: '/student'), '/student/home');
  });

  test('assistant screens are gated by staff permissions', () {
    final assistant = _session(UserRole.assistant);
    const limited = StaffMember(
      id: 's',
      tenantId: 't',
      userId: 'u',
      type: StaffType.supervisor,
      permissions: {Permission.attendance},
    );
    expect(resolveRedirect(session: assistant, staff: limited, path: '/assistant/scanner'),
        isNull);
    expect(resolveRedirect(session: assistant, staff: limited, path: '/assistant/payments'),
        '/assistant/home');
  });
}
