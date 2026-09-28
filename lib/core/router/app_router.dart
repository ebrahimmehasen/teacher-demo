import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/assistant/assistant_shell.dart';
import '../../features/assistant/grades/grades_entry_page.dart';
import '../../features/assistant/home/assistant_home_page.dart';
import '../../features/assistant/manual_attendance/manual_attendance_page.dart';
import '../../features/assistant/payments/payments_page.dart';
import '../../features/assistant/scanner/scanner_page.dart';
import '../../features/assistant/sheets/sheet_sales_page.dart';
import '../../features/assistant/students/assistant_students_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/parent/parent_shell.dart';
import '../../features/platform_admin/admin_shell.dart';
import '../../features/shared/announcements/announcements_list_page.dart';
import '../../features/shared/assessments/my_results_page.dart';
import '../../features/shared/attendance/attendance_log_page.dart';
import '../../features/shared/attendance/my_attendance_page.dart';
import '../../features/shared/coming_soon_page.dart';
import '../../features/shared/lessons/recorded_lessons_page.dart';
import '../../features/shared/schedule/my_schedule_page.dart';
import '../../features/student/home/student_home_page.dart';
import '../../features/student/more/student_more_page.dart';
import '../../features/student/more/student_profile_page.dart';
import '../../features/student/qr/student_qr_page.dart';
import '../../features/student/requests/student_requests_page.dart';
import '../../features/student/student_shell.dart';
import '../../features/teacher/dashboard/dashboard_page.dart';
import '../../features/teacher/schedule/schedule_page.dart';
import '../../features/teacher/settings/settings_page.dart';
import '../../features/teacher/students/students_page.dart';
import '../../features/teacher/teacher_shell.dart';
import '../../services/session_service.dart';
import 'role_destinations.dart';
import 'route_guard.dart';

typedef _ShellBuilder = Widget Function(String location, Widget child);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.listen(currentStaffProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: loginPath,
    refreshListenable: refresh,
    redirect: (context, state) => resolveRedirect(
      session: ref.read(sessionProvider),
      staff: ref.read(currentStaffProvider).asData?.value,
      path: state.uri.path,
    ),
    routes: [
      GoRoute(path: loginPath, builder: (_, _) => const LoginPage()),
      _roleShell(
        RoleDestinations.teacher,
        (location, child) => TeacherShell(location: location, child: child),
      ),
      _roleShell(
        RoleDestinations.assistant,
        (location, child) => AssistantShell(location: location, child: child),
      ),
      _roleShell(
        RoleDestinations.student,
        (location, child) => StudentShell(location: location, child: child),
      ),
      _roleShell(
        RoleDestinations.parent,
        (location, child) => ParentShell(location: location, child: child),
      ),
      _roleShell(
        RoleDestinations.platformAdmin,
        (location, child) => AdminShell(location: location, child: child),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

/// Built screens by path; every other destination shows [ComingSoonPage].
final Map<String, Widget Function()> _pages = {
  '/teacher/dashboard': () => const DashboardPage(),
  '/teacher/schedule': () => const SchedulePage(),
  '/teacher/students': () => const StudentsPage(),
  '/teacher/settings': () => const SettingsPage(),
  '/teacher/attendance': () => const AttendanceLogPage(),
  '/assistant/home': () => const AssistantHomePage(),
  '/assistant/scanner': () => const ScannerPage(),
  '/assistant/manual-attendance': () => const ManualAttendancePage(),
  '/assistant/attendance': () => const AttendanceLogPage(),
  '/assistant/students': () => const AssistantStudentsPage(),
  '/assistant/payments': () => const PaymentsPage(),
  '/assistant/sheets': () => const SheetSalesPage(),
  '/assistant/grades': () => const GradesEntryPage(),
  '/student/home': () => const StudentHomePage(),
  '/student/qr': () => const StudentQrPage(),
  '/student/schedule': () => const MySchedulePage(),
  '/student/requests': () => const StudentRequestsPage(),
  '/student/more': () => const StudentMorePage(),
};

/// Sub-pages reached through "المزيد" (not their own bottom-nav tab), shared
/// with the parent role in a later phase.
final Map<String, Widget Function()> _moreSubPages = {
  'profile': () => const StudentProfilePage(),
  'attendance': () => const MyAttendancePage(),
  'grades': () => const MyResultsPage(),
  'lessons': () => const RecordedLessonsPage(),
  'announcements': () => const AnnouncementsListPage(),
};

ShellRoute _roleShell(List<RoleDestination> destinations, _ShellBuilder shell) => ShellRoute(
  builder: (context, state, child) => shell(state.uri.path, child),
  routes: [
    for (final d in destinations)
      GoRoute(
        path: d.path,
        pageBuilder: (_, _) =>
            NoTransitionPage(child: _pages[d.path]?.call() ?? ComingSoonPage(destination: d)),
        routes: [
          if (d.path.endsWith('/more'))
            for (final entry in _moreSubPages.entries)
              GoRoute(
                path: entry.key,
                pageBuilder: (_, _) => NoTransitionPage(child: entry.value()),
              ),
        ],
      ),
  ],
);
