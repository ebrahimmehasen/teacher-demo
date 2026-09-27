import 'package:flutter/material.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/models.dart';
import '../../../services/attendance_service.dart';

sealed class ScanOutcome {
  const ScanOutcome();
}

class ScanRecorded extends ScanOutcome {
  const ScanRecorded(this.preview, this.record, {this.undone = false});
  final ScanPreview preview;
  final Attendance record;
  final bool undone;
}

class ScanDuplicate extends ScanOutcome {
  const ScanDuplicate(this.preview);
  final ScanPreview preview;
}

class ScanFailed extends ScanOutcome {
  const ScanFailed(this.message);
  final String message;
}

class ScanResultCard extends StatelessWidget {
  const ScanResultCard({super.key, required this.outcome, this.onUndo, this.undoing = false});

  final ScanOutcome? outcome;
  final VoidCallback? onUndo;
  final bool undoing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outcome = this.outcome;
    if (outcome == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.qr_code_scanner, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text('وجّه الكاميرا إلى كود الطالب', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'ستظهر نتيجة المسح هنا فوراً',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return switch (outcome) {
      ScanFailed(:final message) => _Frame(
        tone: StatusTone.danger,
        icon: Icons.error_outline,
        title: 'كود غير صالح',
        child: Text(message, style: theme.textTheme.bodyLarge),
      ),
      ScanDuplicate(:final preview) => _Frame(
        tone: StatusTone.warning,
        icon: Icons.history,
        title: 'مسجل مسبقاً',
        child: _StudentSummary(
          preview: preview,
          trailing: Text(
            'تم تسجيله الساعة ${preview.existing?.scanTime == null ? '—' : AppDates.time(preview.existing!.scanTime!)}',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ),
      ScanRecorded(:final preview, :final undone) => _Frame(
        tone: undone
            ? StatusTone.neutral
            : (preview.status == AttendanceStatus.late ? StatusTone.warning : StatusTone.success),
        icon: undone ? Icons.undo : Icons.check_circle,
        title: undone ? 'تم التراجع عن التسجيل' : 'تم تسجيل الحضور',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StudentSummary(
              preview: preview,
              trailing: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  StatusChip.attendance(preview.status),
                  if (preview.isMakeup)
                    const StatusChip(
                      label: 'حصة تعويض',
                      tone: StatusTone.info,
                      icon: Icons.swap_horiz,
                    ),
                ],
              ),
            ),
            if (!undone && onUndo != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: OutlinedButton.icon(
                  onPressed: undoing ? null : onUndo,
                  icon: const Icon(Icons.undo),
                  label: const Text('تراجع عن آخر مسح'),
                ),
              ),
            ],
          ],
        ),
      ),
    };
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.tone, required this.icon, required this.title, required this.child});

  final StatusTone tone;
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = toneColor(context, tone);
    return Card(
      color: Color.alphaBlend(
        color.withValues(alpha: 0.08),
        Theme.of(context).cardTheme.color ?? Colors.white,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _StudentSummary extends StatelessWidget {
  const _StudentSummary({required this.preview, required this.trailing});

  final ScanPreview preview;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            preview.student.name.characters.first,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                preview.student.name,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(preview.groupLabel, style: muted),
              Text(
                '${AppDates.time(preview.scanTime)}'
                '${preview.status == AttendanceStatus.late ? ' • تأخير ${preview.lateMinutes} دقيقة' : ''}',
                style: muted,
              ),
              const SizedBox(height: 8),
              trailing,
            ],
          ),
        ),
      ],
    );
  }
}
