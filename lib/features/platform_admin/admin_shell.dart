import 'package:flutter/material.dart';

import '../../core/router/role_destinations.dart';
import '../shared/shell/adaptive_shell.dart';
import '../shared/shell/shell_header.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AdaptiveShell(
      destinations: RoleDestinations.platformAdmin,
      location: location,
      header: const ShellHeader(title: 'إدارة المنصة', subtitle: 'حسابات المدرسين والاشتراكات'),
      child: child,
    );
  }
}
