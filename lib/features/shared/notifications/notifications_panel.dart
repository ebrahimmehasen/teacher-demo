import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/models.dart';
import '../../../data/repository_providers.dart';
import '../../../services/session_service.dart';
import '../../../services/notification_service.dart';

IconData _iconFor(NotificationType type) => switch (type) {
  NotificationType.attendance => Icons.fact_check_outlined,
  NotificationType.payment => Icons.payments_outlined,
  NotificationType.announcement => Icons.campaign_outlined,
  NotificationType.request => Icons.mail_outline,
  NotificationType.complaint => Icons.warning_amber_outlined,
  NotificationType.general => Icons.notifications_outlined,
};

/// Opens the notification list in a bottom sheet; tapping an item marks it
/// read and follows its deep link.
Future<void> showNotificationsPanel(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  constraints: const BoxConstraints(maxWidth: 560),
  builder: (_) => const _NotificationsPanel(),
);

class _NotificationsPanel extends ConsumerWidget {
  const _NotificationsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications =
        ref.watch(myNotificationsProvider).asData?.value ?? const <AppNotification>[];
    final theme = Theme.of(context);
    final userId = ref.watch(sessionProvider)?.user.id;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
            child: Row(
              children: [
                Text(
                  'الإشعارات',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (notifications.any((n) => !n.read) && userId != null)
                  TextButton(
                    onPressed: () => ref.read(notificationRepositoryProvider).markAllRead(userId),
                    child: const Text('تحديد الكل كمقروء'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: notifications.isEmpty
                ? const EmptyState(icon: Icons.notifications_none, title: 'لا توجد إشعارات بعد')
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final n = notifications[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: n.read
                              ? theme.colorScheme.surfaceContainerHighest
                              : theme.colorScheme.primaryContainer,
                          child: Icon(
                            _iconFor(n.type),
                            size: 20,
                            color: n.read
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(
                          n.title,
                          style: TextStyle(
                            fontWeight: n.read ? FontWeight.normal : FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${n.body}\n${AppDates.dayMonth(n.createdAt)} • ${AppDates.time(n.createdAt)}',
                        ),
                        isThreeLine: true,
                        trailing: n.read
                            ? null
                            : Icon(Icons.circle, size: 10, color: theme.colorScheme.primary),
                        onTap: () {
                          if (!n.read && userId != null) {
                            ref.read(notificationRepositoryProvider).markRead(userId, n.id);
                          }
                          Navigator.of(context).pop();
                          if (n.deepLink != null) context.go(n.deepLink!);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
