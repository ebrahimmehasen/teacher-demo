import 'package:flutter/material.dart';

import '../../core/router/role_destinations.dart';
import '../../core/widgets/empty_state.dart';

/// Placeholder for screens that later phases will build.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.destination});

  final RoleDestination destination;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: destination.icon,
      title: destination.label,
      message: 'هذه الشاشة قيد التجهيز وستكون متاحة قريباً.',
    );
  }
}
