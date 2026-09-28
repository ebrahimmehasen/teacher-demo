import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/labels.dart';
import '../../../core/theme/status_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/enums.dart';
import '../../../services/payment_status_service.dart';
import '../../../services/session_service.dart';
import '../../../services/student_context.dart';

/// Current month's subscription: amount, status, and — when due or overdue —
/// the accepted payment methods and wallet numbers so the parent can pay.
class PaymentStatusCard extends ConsumerWidget {
  const PaymentStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billing = ref.watch(activeStudentBillingProvider).asData?.value ?? const [];
    if (billing.isEmpty) return const SizedBox.shrink();
    final b = billing.first;
    final tenant = ref.watch(currentTenantProvider).asData?.value;
    final theme = Theme.of(context);
    final overdue = b.status == PaymentStatus.overdue;
    final remaining = b.price - b.paid;

    return SectionCard(
      title: 'اشتراك الشهر',
      trailing: StatusChip.payment(b.status),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (b.status == PaymentStatus.exempt)
            const Text('الطالب معفى من الاشتراك.')
          else ...[
            Text('${Money.format(b.price)} شهرياً', style: theme.textTheme.titleMedium),
            if (b.status != PaymentStatus.paid)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'المتبقي: ${Money.format(remaining)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
          ],
          if (overdue && tenant != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: StatusColors.of(context).danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: StatusColors.of(context).danger),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('الاشتراك متأخر، برجاء السداد في أقرب وقت.')),
                ],
              ),
            ),
          ],
          if ((b.status == PaymentStatus.due || overdue) && tenant != null) ...[
            const SizedBox(height: 12),
            Text('طرق الدفع المتاحة', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            for (final method in tenant.settings.acceptedPaymentMethods)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      '${method.label}: ',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Expanded(
                      child: Text(
                        tenant.settings.walletNumbers[method] ??
                            (method == PaymentMethod.cash ? 'عند المساعد' : '—'),
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
