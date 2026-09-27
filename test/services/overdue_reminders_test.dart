import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:teacher_demo/core/constants/demo_accounts.dart';
import 'package:teacher_demo/data/mock/mock_database.dart';
import 'package:teacher_demo/data/mock/seed_generator.dart';
import 'package:teacher_demo/data/models/models.dart';
import 'package:teacher_demo/data/repository_providers.dart';
import 'package:teacher_demo/services/session_service.dart';
import 'package:teacher_demo/services/tenant_data.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  test('overdue reminders reach the demo parent once, even when re-run', () async {
    final now = DateTime(2026, 9, 27, 12);
    final db = MockDatabase(SeedGenerator(now: now).generate(), latency: () => Duration.zero);
    final container = ProviderContainer(
      overrides: [
        mockDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(sessionProvider.notifier)
        .signIn(phone: DemoAccounts.teacherPhone, password: DemoAccounts.password);

    final sub = container.listen(overdueRemindersProvider, (_, _) {});
    final created = await container.read(overdueRemindersProvider.future);
    expect(created, greaterThan(0));

    List<AppNotification> overdueFor(String userId) => db.notifications.rows
        .where((n) => n.userId == userId && n.type == NotificationType.payment)
        .toList();

    // Demo student is unpaid this month (27th > due day 5 + 5 grace days).
    final parentReminders = overdueFor(SeedGenerator.parentUserId(0));
    expect(parentReminders, isNotEmpty);
    expect(parentReminders.first.body, contains('متأخر'));
    expect(overdueFor(SeedGenerator.studentUserId(0)), isNotEmpty);

    final before = db.notifications.rows.length;
    container.invalidate(overdueRemindersProvider);
    await container.read(overdueRemindersProvider.future);
    expect(db.notifications.rows.length, before);

    // The exempt student never gets a reminder.
    final exempt = db.enrollments.rows.singleWhere((e) => e.isExempt);
    expect(overdueFor(exempt.studentId), isEmpty);
    sub.close();
  });
}
