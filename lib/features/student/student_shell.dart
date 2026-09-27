import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/role_destinations.dart';
import '../../services/session_service.dart';
import '../shared/shell/bottom_nav_shell.dart';
import '../shared/shell/shell_header.dart';

class StudentShell extends ConsumerWidget {
  const StudentShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final tenant = ref.watch(currentTenantProvider).asData?.value;
    return BottomNavShell(
      destinations: RoleDestinations.student,
      location: location,
      title: ShellHeader(
        title: session?.user.name ?? '',
        subtitle: tenant == null ? null : '${tenant.teacherName} – ${tenant.subject}',
      ),
      child: child,
    );
  }
}
