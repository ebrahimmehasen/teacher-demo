import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/role_destinations.dart';
import '../../services/session_service.dart';
import '../../services/student_context.dart';
import '../shared/shell/bottom_nav_shell.dart';
import '../shared/shell/parent_switcher_bar.dart';
import '../shared/shell/shell_header.dart';

class ParentShell extends ConsumerWidget {
  const ParentShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final tenant = ref.watch(currentTenantProvider).asData?.value;
    final activeChild = ref.watch(activeStudentProvider).asData?.value;
    final subtitle = [
      if (activeChild != null) activeChild.name,
      if (tenant != null) '${tenant.teacherName} – ${tenant.subject}',
    ].join(' • ');

    return BottomNavShell(
      destinations: RoleDestinations.parent,
      location: location,
      title: ShellHeader(
        title: session?.user.name ?? '',
        subtitle: subtitle.isEmpty ? null : subtitle,
      ),
      banner: const ParentSwitcherBar(),
      child: child,
    );
  }
}
