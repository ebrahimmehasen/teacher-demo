import '../../data/models/enums.dart';

class DemoAccount {
  const DemoAccount({required this.role, required this.label, required this.phone});

  final UserRole role;
  final String label;
  final String phone;
  String get password => DemoAccounts.password;
}

/// Mock-only credentials shown as quick-login chips; the seed creates these users.
abstract final class DemoAccounts {
  static const password = '123456';

  static const platformAdminPhone = '01000000000';
  static const teacherPhone = '01000000001';
  static const secondTeacherPhone = '01000000002';
  static const assistantPhone = '01100000001';
  static const limitedAssistantPhone = '01100000002';
  static const studentPhone = '01200000000';
  static const parentPhone = '01500000000';

  static const all = [
    DemoAccount(role: UserRole.teacher, label: 'مدرس', phone: teacherPhone),
    DemoAccount(role: UserRole.assistant, label: 'مساعد', phone: assistantPhone),
    DemoAccount(role: UserRole.student, label: 'طالب', phone: studentPhone),
    DemoAccount(role: UserRole.parent, label: 'ولي أمر', phone: parentPhone),
    DemoAccount(role: UserRole.platformAdmin, label: 'إدارة المنصة', phone: platformAdminPhone),
  ];
}
