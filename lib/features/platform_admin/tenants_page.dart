import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/labels.dart';
import '../../core/theme/status_colors.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_container.dart';
import '../../core/widgets/snackbars.dart';
import '../../data/models/models.dart';
import '../../services/platform_admin_service.dart';
import '../../services/tenant_data.dart';
import 'add_teacher_dialog.dart';

class TenantsPage extends ConsumerWidget {
  const TenantsPage({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final draft = await showAddTeacherDialog(context);
    if (draft == null) return;
    try {
      await ref
          .read(platformAdminServiceProvider)
          .addTeacher(
            teacherName: draft.teacherName,
            subject: draft.subject,
            phone: draft.phone,
            plan: draft.plan,
          );
      if (context.mounted) {
        showSuccessSnack(
          context,
          'تمت الإضافة – كلمة المرور ${PlatformAdminService.defaultPassword}',
        );
      }
    } on PlatformAdminException catch (e) {
      if (context.mounted) showErrorSnack(context, e.message);
    }
  }

  Future<void> _toggleStatus(BuildContext context, WidgetRef ref, Tenant tenant) async {
    final activating = tenant.subscriptionStatus != SubscriptionStatus.active;
    final ok = await showConfirmDialog(
      context,
      title: activating ? 'تفعيل الحساب' : 'إيقاف الحساب',
      message: activating
          ? 'هل تريد تفعيل حساب ${tenant.teacherName}؟'
          : 'هل تريد إيقاف حساب ${tenant.teacherName}؟ لن يتمكن من تسجيل الدخول.',
      confirmLabel: activating ? 'تفعيل' : 'إيقاف',
      destructive: !activating,
    );
    if (!ok) return;
    await ref
        .read(platformAdminServiceProvider)
        .setStatus(tenant, activating ? SubscriptionStatus.active : SubscriptionStatus.expired);
    if (context.mounted) showSuccessSnack(context, activating ? 'تم التفعيل' : 'تم الإيقاف');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueView(
      value: ref.watch(allTenantsProvider),
      builder: (tenants) {
        if (tenants.isEmpty) {
          return EmptyState(
            icon: Icons.school_outlined,
            title: 'لا يوجد مدرسون بعد',
            action: FilledButton.icon(
              onPressed: () => _add(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('إضافة مدرس'),
            ),
          );
        }
        return PageContainer(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: () => _add(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('إضافة مدرس'),
              ),
            ),
            const SizedBox(height: 12),
            for (final tenant in tenants)
              _TenantCard(tenant: tenant, onToggle: () => _toggleStatus(context, ref, tenant)),
          ],
        );
      },
    );
  }
}

class _TenantCard extends ConsumerWidget {
  const _TenantCard({required this.tenant, required this.onToggle});
  final Tenant tenant;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final count = ref.watch(tenantStudentCountProvider(tenant.id)).asData?.value;
    final active = tenant.subscriptionStatus == SubscriptionStatus.active;
    final statusColor = switch (tenant.subscriptionStatus) {
      SubscriptionStatus.active => StatusColors.of(context).success,
      SubscriptionStatus.trial => StatusColors.of(context).info,
      SubscriptionStatus.expired => StatusColors.of(context).danger,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(radius: 26, child: Text(tenant.teacherName.characters.first)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tenant.teacherName,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${tenant.subject} • ${tenant.phone}',
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Chip(
                        label: Text(tenant.subscriptionStatus.label),
                        backgroundColor: statusColor.withValues(alpha: 0.12),
                        labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      ),
                      Chip(
                        label: Text(tenant.subscriptionPlan.label),
                        visualDensity: VisualDensity.compact,
                      ),
                      Chip(
                        avatar: const Icon(Icons.groups_outlined, size: 16),
                        label: Text(count == null ? '...' : '$count طالب'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Switch(value: active, onChanged: (_) => onToggle()),
          ],
        ),
      ),
    );
  }
}
