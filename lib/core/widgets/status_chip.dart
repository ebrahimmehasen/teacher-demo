import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../../services/payment_status_service.dart';
import '../constants/labels.dart';
import '../theme/status_colors.dart';

enum StatusTone { success, warning, info, danger, neutral }

Color toneColor(BuildContext context, StatusTone tone) {
  final c = StatusColors.of(context);
  return switch (tone) {
    StatusTone.success => c.success,
    StatusTone.warning => c.warning,
    StatusTone.info => c.info,
    StatusTone.danger => c.danger,
    StatusTone.neutral => c.neutral,
  };
}

/// Status is always icon + label + color, never color alone.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.tone, this.icon});

  StatusChip.payment(PaymentStatus status, {super.key})
    : label = status.label,
      tone = status.tone,
      icon = status.icon;

  StatusChip.attendance(AttendanceStatus status, {super.key})
    : label = status.label,
      tone = status.tone,
      icon = status.icon;

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = toneColor(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

extension PaymentStatusUi on PaymentStatus {
  String get label => switch (this) {
    PaymentStatus.paid => 'مدفوع',
    PaymentStatus.due => 'مستحق',
    PaymentStatus.overdue => 'متأخر',
    PaymentStatus.exempt => 'معفى',
  };

  StatusTone get tone => switch (this) {
    PaymentStatus.paid => StatusTone.success,
    PaymentStatus.due => StatusTone.warning,
    PaymentStatus.overdue => StatusTone.danger,
    PaymentStatus.exempt => StatusTone.neutral,
  };

  IconData get icon => switch (this) {
    PaymentStatus.paid => Icons.check_circle_outline,
    PaymentStatus.due => Icons.schedule,
    PaymentStatus.overdue => Icons.error_outline,
    PaymentStatus.exempt => Icons.remove_circle_outline,
  };
}

extension AttendanceStatusUi on AttendanceStatus {
  StatusTone get tone => switch (this) {
    AttendanceStatus.present => StatusTone.success,
    AttendanceStatus.late => StatusTone.warning,
    AttendanceStatus.absentExcused => StatusTone.info,
    AttendanceStatus.absent => StatusTone.danger,
  };

  IconData get icon => switch (this) {
    AttendanceStatus.present => Icons.check_circle_outline,
    AttendanceStatus.late => Icons.timer_outlined,
    AttendanceStatus.absentExcused => Icons.info_outline,
    AttendanceStatus.absent => Icons.cancel_outlined,
  };
}
