import '../../data/models/enums.dart';

extension UserRoleLabel on UserRole {
  String get label => switch (this) {
    UserRole.teacher => 'مدرس',
    UserRole.assistant => 'مساعد',
    UserRole.student => 'طالب',
    UserRole.parent => 'ولي أمر',
    UserRole.platformAdmin => 'إدارة المنصة',
  };
}

extension StaffTypeLabel on StaffType {
  String get label => switch (this) {
    StaffType.assistant => 'مساعد',
    StaffType.supervisor => 'مشرف',
  };
}

extension PermissionLabel on Permission {
  String get label => switch (this) {
    Permission.attendance => 'الحضور',
    Permission.students => 'الطلاب',
    Permission.payments => 'المدفوعات',
    Permission.sheets => 'المذكرات',
    Permission.grades => 'الدرجات',
    Permission.accounts => 'الحسابات',
    Permission.announcements => 'الإعلانات',
  };
}

extension AttendanceStatusLabel on AttendanceStatus {
  String get label => switch (this) {
    AttendanceStatus.present => 'حاضر',
    AttendanceStatus.late => 'متأخر',
    AttendanceStatus.absentExcused => 'غائب بعذر',
    AttendanceStatus.absent => 'غائب',
  };
}

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.cash => 'كاش',
    PaymentMethod.vodafoneCash => 'فودافون كاش',
    PaymentMethod.instaPay => 'إنستاباي',
    PaymentMethod.bankTransfer => 'تحويل بنكي',
    PaymentMethod.fawry => 'فوري',
    PaymentMethod.other => 'أخرى',
  };
}

extension GroupTypeLabel on GroupType {
  String get label => switch (this) {
    GroupType.public => 'عامة',
    GroupType.private => 'خاصة',
  };
}

extension SubscriptionStatusLabel on SubscriptionStatus {
  String get label => switch (this) {
    SubscriptionStatus.active => 'نشط',
    SubscriptionStatus.trial => 'تجريبي',
    SubscriptionStatus.expired => 'منتهي',
  };
}

abstract final class GroupLabels {
  static const _ordinals = [
    'الأولى',
    'الثانية',
    'الثالثة',
    'الرابعة',
    'الخامسة',
    'السادسة',
    'السابعة',
    'الثامنة',
    'التاسعة',
    'العاشرة',
  ];

  /// 1 ⇒ "المجموعة الأولى".
  static String name(int number) =>
      'المجموعة ${number >= 1 && number <= _ordinals.length ? _ordinals[number - 1] : number}';
}
