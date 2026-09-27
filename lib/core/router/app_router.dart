import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/assistant/assistant_shell.dart';
import '../../features/auth/login_page.dart';
import '../../features/parent/parent_shell.dart';
import '../../features/platform_admin/admin_shell.dart';
import '../../features/shared/coming_soon_page.dart';
import '../../features/student/student_shell.dart';
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
      _roleShell(RoleDestinations.teacher,
          (location, child) => TeacherShell(location: location, child: child)),
      _roleShell(RoleDestinations.assistant,
          (location, child) => AssistantShell(location: location, child: child)),
      _roleShell(RoleDestinations.student,
          (location, child) => StudentShell(location: location, child: child)),
      _roleShell(RoleDestinations.parent,
          (location, child) => ParentShell(location: location, child: child)),
      _roleShell(RoleDestinations.platformAdmin,
          (location, child) => AdminShell(location: location, child: child)),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

ShellRoute _roleShell(List<RoleDestination> destinations, _ShellBuilder shell) => ShellRoute(
      builder: (context, state, child) => shell(state.uri.path, child),
      routes: [
        for (final d in destinations)
          GoRoute(
            path: d.path,
            pageBuilder: (_, _) => NoTransitionPage(child: ComingSoonPage(destination: d)),
          ),
      ],
    );
