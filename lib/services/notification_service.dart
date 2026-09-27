import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/models.dart';
import '../data/repository_providers.dart';
import 'session_service.dart';

final myNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final userId = ref.watch(sessionProvider.select((s) => s?.user.id));
  if (userId == null) return Stream.value(const []);
  return ref.watch(notificationRepositoryProvider).watchForUser(userId);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(myNotificationsProvider).asData?.value ?? const [];
  return notifications.where((n) => !n.read).length;
});
