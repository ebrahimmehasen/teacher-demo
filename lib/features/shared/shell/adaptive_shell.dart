import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/role_destinations.dart';
import '../../../core/widgets/notification_bell.dart';
import 'account_menu.dart';

/// Staff shell: side NavigationRail on tablet/web, Drawer on phones.
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({
    super.key,
    required this.destinations,
    required this.location,
    required this.header,
    required this.child,
  });

  static const wideBreakpoint = 840.0;

  final List<RoleDestination> destinations;
  final String location;

  /// Shown at the top of the drawer / rail (teacher name, subject...).
  final Widget header;
  final Widget child;

  int get _selectedIndex {
    final index = destinations.indexWhere(
      (d) => location == d.path || location.startsWith('${d.path}/'),
    );
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    final selected = _selectedIndex;
    final title = destinations.isEmpty ? '' : destinations[selected].label;

    final appBar = AppBar(title: Text(title), actions: const [NotificationBell(), AccountMenu()]);

    if (!wide) {
      return Scaffold(
        appBar: appBar,
        drawer: NavigationDrawer(
          selectedIndex: selected,
          onDestinationSelected: (i) {
            Navigator.of(context).pop();
            context.go(destinations[i].path);
          },
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: header),
            const Divider(indent: 16, endIndent: 16),
            const SizedBox(height: 8),
            for (final d in destinations)
              NavigationDrawerDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: Text(d.label),
              ),
          ],
        ),
        body: child,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _ScrollableRail(
            header: header,
            selectedIndex: selected,
            destinations: destinations,
            onSelected: (i) => context.go(destinations[i].path),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Scaffold(appBar: appBar, body: child),
          ),
        ],
      ),
    );
  }
}

class _ScrollableRail extends StatelessWidget {
  const _ScrollableRail({
    required this.header,
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
  });

  final Widget header;
  final int selectedIndex;
  final List<RoleDestination> destinations;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: NavigationRail(
              extended: true,
              minExtendedWidth: 232,
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelected,
              leading: SizedBox(
                width: 208,
                child: Padding(padding: const EdgeInsets.only(bottom: 8), child: header),
              ),
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
