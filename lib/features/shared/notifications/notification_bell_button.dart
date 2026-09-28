import 'package:flutter/material.dart';

import '../../../core/widgets/notification_bell.dart';
import 'notifications_panel.dart';

/// The bell icon wired to open the notifications panel; used by every shell.
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) =>
      NotificationBell(onPressed: () => showNotificationsPanel(context));
}
