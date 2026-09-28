import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/models.dart';
import '../../../services/session_service.dart';
import '../../../services/student_context.dart';
import '../../../services/tenant_data.dart';

/// Teacher/subject switcher, shown whenever the active student has more than
/// one enrollment. Required by the spec for both student and parent screens.
class EnrollmentSwitcher extends ConsumerWidget {
  const EnrollmentSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollments =
        ref.watch(activeStudentEnrollmentsProvider).asData?.value ?? const <Enrollment>[];
    final tenantIds = {for (final e in enrollments.where((e) => e.active)) e.tenantId};
    if (tenantIds.length < 2) return const SizedBox.shrink();

    final tenants = {
      for (final t in ref.watch(allTenantsProvider).asData?.value ?? const <Tenant>[]) t.id: t,
    };
    final currentTenantId = ref.watch(sessionProvider.select((s) => s?.tenantId));
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            for (final tenantId in tenantIds)
              if (tenants[tenantId] case final tenant?)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text('${tenant.teacherName} – ${tenant.subject}'),
                    selected: tenantId == currentTenantId,
                    onSelected: (_) => ref.read(sessionProvider.notifier).selectTenant(tenantId),
                    labelStyle: theme.textTheme.bodySmall,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
