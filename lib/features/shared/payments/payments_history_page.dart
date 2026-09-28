import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/labels.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_container.dart';
import '../../../services/student_context.dart';
import '../home/payment_status_card.dart';

/// Read-only payment history for the active student, with the current
/// month's status card on top.
class PaymentsHistoryPage extends ConsumerWidget {
  const PaymentsHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueView(
      value: ref.watch(activeStudentPaymentsProvider),
      builder: (payments) {
        final sorted = [...payments]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return PageContainer(
          children: [
            const PaymentStatusCard(),
            const SizedBox(height: 16),
            if (sorted.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'لا توجد مدفوعات مسجلة بعد',
              )
            else
              for (final p in sorted)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
                    title: Text(Money.format(p.amount)),
                    subtitle: Text(
                      '${AppDates.monthYear(AppDates.parseMonthKey(p.month))} • ${p.method.label}'
                      '${p.referenceNumber == null ? '' : ' • ${p.referenceNumber}'}',
                    ),
                    trailing: Text(AppDates.short(p.createdAt), textDirection: TextDirection.ltr),
                  ),
                ),
          ],
        );
      },
    );
  }
}
