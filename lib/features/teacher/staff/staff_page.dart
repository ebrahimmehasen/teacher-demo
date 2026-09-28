import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/labels.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../data/models/models.dart';
import '../../../data/repository_providers.dart';
import '../../../services/session_service.dart';
import '../../../services/staff_service.dart';
import '../../../services/tenant_data.dart';
import 'staff_form_dialog.dart';

/// Users of the current tenant's staff, keyed by id.
final _staffUsersProvider = StreamProvider<Map<String, User>>((ref) async* {
  final members = await ref.watch(staffProvider.future);
  final ids = {for (final m in members) m.userId};
  yield* ref
      .watch(userRepositoryProvider)
      .watchByIds(ids)
      .map((users) => {for (final u in users) u.id: u});
});

class StaffPage extends ConsumerWidget {
  const StaffPage({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final draft = await showStaffFormDialog(context);
    if (draft == null) return;
    final tenantId = ref.read(sessionProvider)!.tenantId!;
    try {
      await ref
          .read(staffServiceProvider)
          .add(
            tenantId: tenantId,
            name: draft.name,
            phone: draft.phone,
            type: draft.type,
            permissions: draft.permissions,
          );
      if (context.mounted) {
        showSuccessSnack(context, 'تمت الإضافة – كلمة المرور ${StaffService.defaultPassword}');
      }
    } on StaffServiceException catch (e) {
      if (context.mounted) showErrorSnack(context, e.message);
    }
  }

  Future<void> _togglePermission(WidgetRef ref, StaffMember member, Permission p) {
    final permissions = {...member.permissions};
    permissions.contains(p) ? permissions.remove(p) : permissions.add(p);
    return ref.read(staffServiceProvider).updatePermissions(member, permissions);
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, StaffMember member, String name) async {
    final ok = await showConfirmDialog(
      context,
      title: 'إزالة مساعد',
      message: 'هل تريد إزالة $name من فريق العمل؟',
      confirmLabel: 'إزالة',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(staffServiceProvider).remove(member);
    if (context.mounted) showSuccessSnack(context, 'تمت الإزالة');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(_staffUsersProvider).asData?.value ?? const <String, User>{};

    return AsyncValueView(
      value: ref.watch(staffProvider),
      builder: (members) => PageContainer(
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              onPressed: () => _add(context, ref),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('إضافة مساعد'),
            ),
          ),
          const SizedBox(height: 12),
          if (members.isEmpty)
            const EmptyState(icon: Icons.badge_outlined, title: 'لا يوجد مساعدون بعد')
          else
            for (final m in members)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            child: Text((users[m.userId]?.name ?? '؟').characters.first),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  users[m.userId]?.name ?? '',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  '${m.type.label} • ${users[m.userId]?.phone ?? ''}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  textDirection: TextDirection.ltr,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'إزالة',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _remove(context, ref, m, users[m.userId]?.name ?? ''),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final p in Permission.values)
                            FilterChip(
                              label: Text(p.label),
                              selected: m.can(p),
                              onSelected: (_) => _togglePermission(ref, m, p),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
