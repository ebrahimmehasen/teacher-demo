import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/role_destinations.dart';
import '../../../core/widgets/notification_bell.dart';
import 'account_menu.dart';

/// Student / parent shell with a bottom NavigationBar.
class BottomNavShell extends StatelessWidget {
  const BottomNavShell({
    super.key,
    required this.destinations,
    required this.location,
    required this.title,
    required this.child,
    this.banner,
  });

  final List<RoleDestination> destinations;
  final String location;
  final Widget title;
  final Widget child;

  /// Extra content above the page, e.g. the child / teacher switcher. Any
  /// height; collapses to nothing when the widget itself renders empty.
  final Widget? banner;

  @override
  Widget build(BuildContext context) {
    final index = destinations.indexWhere(
      (d) => location == d.path || location.startsWith('${d.path}/'),
    );

    return Scaffold(
      appBar: AppBar(title: title, actions: const [NotificationBell(), AccountMenu()]),
      body: Column(
        children: [
          ?banner,
          Expanded(
            child: Center(
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: child),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (i) => context.go(destinations[i].path),
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
