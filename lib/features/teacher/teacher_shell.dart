import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/role_destinations.dart';
import '../../services/session_service.dart';
import '../shared/shell/adaptive_shell.dart';
import '../shared/shell/shell_header.dart';

class TeacherShell extends ConsumerWidget {
  const TeacherShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenant = ref.watch(currentTenantProvider).asData?.value;
    return AdaptiveShell(
      destinations: RoleDestinations.teacher,
      location: location,
      header: ShellHeader(
        title: tenant?.teacherName ?? '',
        subtitle: tenant == null ? null : 'مادة ${tenant.subject}',
      ),
      child: child,
    );
  }
}
