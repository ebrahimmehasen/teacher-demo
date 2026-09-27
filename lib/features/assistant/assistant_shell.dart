import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/labels.dart';
import '../../core/router/role_destinations.dart';
import '../../services/session_service.dart';
import '../shared/shell/adaptive_shell.dart';
import '../shared/shell/shell_header.dart';

/// Shows only the destinations the assistant's permissions allow.
class AssistantShell extends ConsumerWidget {
  const AssistantShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenant = ref.watch(currentTenantProvider).asData?.value;
    final staff = ref.watch(currentStaffProvider).asData?.value;
    final destinations = [
      for (final d in RoleDestinations.assistant)
        if (d.permission == null || (staff?.can(d.permission!) ?? false)) d,
    ];
    return AdaptiveShell(
      destinations: destinations,
      location: location,
      header: ShellHeader(
        title: tenant?.teacherName ?? '',
        subtitle: staff == null ? null : '${staff.type.label} – مادة ${tenant?.subject ?? ''}',
      ),
      child: child,
    );
  }
}
