import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/labels.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../data/models/models.dart';
import '../../../data/repository_providers.dart';
import '../../../services/group_service.dart';
import '../../../services/pricing_service.dart';
import '../../../services/tenant_data.dart';
import 'group_form_dialog.dart';

Future<void> showGroupDetailsSheet(BuildContext context, Group group) async {
  final edit = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => _GroupDetails(groupId: group.id),
  );
  if (edit == true && context.mounted) {
    await showGroupFormDialog(context, tenantId: group.tenantId, group: group);
  }
}

class _GroupDetails extends ConsumerWidget {
  const _GroupDetails({required this.groupId});
  final String groupId;

  Future<void> _delete(BuildContext context, WidgetRef ref, Group group, int enrolled) async {
    if (enrolled > 0) {
      showErrorSnack(context, 'لا يمكن حذف مجموعة بها $enrolled طالب، انقلهم أولاً');
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: 'حذف المجموعة',
      message: 'هل تريد حذف هذه المجموعة نهائياً؟',
      confirmLabel: 'حذف',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(groupRepositoryProvider).delete(group.tenantId, group.id);
    if (!context.mounted) return;
    showSuccessSnack(context, 'تم حذف المجموعة');
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider).asData?.value ?? const [];
    final group = groups.where((g) => g.id == groupId).firstOrNull;
    if (group == null) return const SizedBox(height: 120);
    final grade = (ref.watch(gradesProvider).asData?.value ?? const <Grade>[])
        .where((g) => g.id == group.gradeId)
        .firstOrNull;
    final enrolled = GroupService.enrolledCount(
      group.id,
      ref.watch(enrollmentsProvider).asData?.value ?? const [],
    );
    final theme = Theme.of(context);
    final accent = group.isPrivate ? AppTheme.privateGroupColor : theme.colorScheme.primary;

    Widget info(IconData icon, String text) => ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: accent),
      title: Text(text, style: theme.textTheme.bodyLarge),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${grade?.name ?? ''} – ${GroupLabels.name(group.number)}',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text('مجموعة ${group.type.label}', style: TextStyle(color: accent)),
            const SizedBox(height: 8),
            if (grade != null)
              info(
                Icons.payments_outlined,
                '${Money.format(PricingService.basePrice(group, grade))} شهرياً',
              ),
            info(Icons.groups_outlined, '$enrolled من ${group.capacity} طالب'),
            if (group.address != null) info(Icons.location_on_outlined, group.address!),
            for (final s in group.sessions)
              info(
                Icons.schedule,
                '${AppDates.weekdayName(s.weekday)} – الفترة ${s.periodIndex + 1}: '
                '${AppDates.clock(s.startTime)} إلى ${AppDates.clock(s.endTime)}',
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('تعديل'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
                    onPressed: () => _delete(context, ref, group, enrolled),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('حذف'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
