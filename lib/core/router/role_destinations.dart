import 'package:flutter/material.dart';

import '../../data/models/enums.dart';

class RoleDestination {
  const RoleDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.permission,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// Staff permission needed to see this destination (assistant only).
  final Permission? permission;
}

abstract final class RoleDestinations {
  static const teacher = [
    RoleDestination(
      path: '/teacher/dashboard',
      label: 'لوحة التحكم',
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard,
    ),
    RoleDestination(
      path: '/teacher/attendance',
      label: 'الحضور',
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check,
    ),
    RoleDestination(
      path: '/teacher/schedule',
      label: 'الجدول',
      icon: Icons.calendar_view_week_outlined,
      selectedIcon: Icons.calendar_view_week,
    ),
    RoleDestination(
      path: '/teacher/students',
      label: 'الطلاب',
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
    ),
    RoleDestination(
      path: '/teacher/sheets',
      label: 'المذكرات والكتب',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
    ),
    RoleDestination(
      path: '/teacher/lessons',
      label: 'الحصص المسجلة',
      icon: Icons.video_library_outlined,
      selectedIcon: Icons.video_library,
    ),
    RoleDestination(
      path: '/teacher/grades',
      label: 'الواجبات والامتحانات',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
    ),
    RoleDestination(
      path: '/teacher/announcements',
      label: 'الإعلانات',
      icon: Icons.campaign_outlined,
      selectedIcon: Icons.campaign,
    ),
    RoleDestination(
      path: '/teacher/requests',
      label: 'الطلبات والشكاوى',
      icon: Icons.inbox_outlined,
      selectedIcon: Icons.inbox,
    ),
    RoleDestination(
      path: '/teacher/accounts',
      label: 'الحسابات',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
    ),
    RoleDestination(
      path: '/teacher/staff',
      label: 'المساعدين',
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge,
    ),
    RoleDestination(
      path: '/teacher/settings',
      label: 'الإعدادات',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  static const assistant = [
    RoleDestination(
      path: '/assistant/home',
      label: 'الرئيسية',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    RoleDestination(
      path: '/assistant/scanner',
      label: 'مسح QR',
      icon: Icons.qr_code_scanner_outlined,
      selectedIcon: Icons.qr_code_scanner,
      permission: Permission.attendance,
    ),
    RoleDestination(
      path: '/assistant/manual-attendance',
      label: 'تسجيل يدوي',
      icon: Icons.checklist_outlined,
      selectedIcon: Icons.checklist,
      permission: Permission.attendance,
    ),
    RoleDestination(
      path: '/assistant/attendance',
      label: 'الحضور',
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check,
      permission: Permission.attendance,
    ),
    RoleDestination(
      path: '/assistant/students',
      label: 'الطلاب',
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
      permission: Permission.students,
    ),
    RoleDestination(
      path: '/assistant/payments',
      label: 'المدفوعات',
      icon: Icons.payments_outlined,
      selectedIcon: Icons.payments,
      permission: Permission.payments,
    ),
    RoleDestination(
      path: '/assistant/sheets',
      label: 'بيع المذكرات',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      permission: Permission.sheets,
    ),
    RoleDestination(
      path: '/assistant/grades',
      label: 'رصد الدرجات',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
      permission: Permission.grades,
    ),
  ];

  static const student = [
    RoleDestination(
      path: '/student/home',
      label: 'الرئيسية',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    RoleDestination(
      path: '/student/qr',
      label: 'QR',
      icon: Icons.qr_code_2_outlined,
      selectedIcon: Icons.qr_code_2,
    ),
    RoleDestination(
      path: '/student/schedule',
      label: 'الجدول',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
    ),
    RoleDestination(
      path: '/student/requests',
      label: 'الطلبات',
      icon: Icons.mail_outline,
      selectedIcon: Icons.mail,
    ),
    RoleDestination(
      path: '/student/more',
      label: 'المزيد',
      icon: Icons.more_horiz,
      selectedIcon: Icons.more_horiz,
    ),
  ];

  static const parent = [
    RoleDestination(
      path: '/parent/home',
      label: 'الرئيسية',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    RoleDestination(
      path: '/parent/attendance',
      label: 'الحضور',
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check,
    ),
    RoleDestination(
      path: '/parent/grades',
      label: 'الدرجات',
      icon: Icons.grading_outlined,
      selectedIcon: Icons.grading,
    ),
    RoleDestination(
      path: '/parent/requests',
      label: 'الطلبات',
      icon: Icons.mail_outline,
      selectedIcon: Icons.mail,
    ),
    RoleDestination(
      path: '/parent/more',
      label: 'المزيد',
      icon: Icons.more_horiz,
      selectedIcon: Icons.more_horiz,
    ),
  ];

  static const platformAdmin = [
    RoleDestination(
      path: '/admin/tenants',
      label: 'المدرسين',
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
    ),
  ];

  static List<RoleDestination> of(UserRole role) => switch (role) {
    UserRole.teacher => teacher,
    UserRole.assistant => assistant,
    UserRole.student => student,
    UserRole.parent => parent,
    UserRole.platformAdmin => platformAdmin,
  };

  static String prefixOf(UserRole role) => switch (role) {
    UserRole.teacher => '/teacher',
    UserRole.assistant => '/assistant',
    UserRole.student => '/student',
    UserRole.parent => '/parent',
    UserRole.platformAdmin => '/admin',
  };

  static String homeOf(UserRole role) => of(role).first.path;

  static RoleDestination? match(UserRole role, String location) {
    for (final d in of(role)) {
      if (location == d.path || location.startsWith('${d.path}/')) return d;
    }
    return null;
  }
}
