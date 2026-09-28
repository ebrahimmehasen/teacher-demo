import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/labels.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../data/models/models.dart';
import '../../../services/request_service.dart';
import '../../../services/session_service.dart';
import '../../../services/student_context.dart';
import '../../../services/tenant_data.dart';
import 'create_request_dialog.dart';

class StudentRequestsPage extends ConsumerWidget {
  const StudentRequestsPage({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final draft = await showCreateRequestDialog(context);
    if (draft == null) return;
    final session = ref.read(sessionProvider)!;
    await ref
        .read(requestServiceProvider)
        .create(
          tenantId: session.tenantId!,
          studentId: session.user.id,
          studentName: session.user.name,
          fromUserId: session.user.id,
          fromRole: session.role,
          type: draft.type,
          text: draft.text,
          now: ref.read(clockProvider)(),
          requestedGroupId: draft.requestedGroupId,
          date: draft.date,
        );
    if (context.mounted) showSuccessSnack(context, 'تم إرسال الطلب');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = ref.watch(groupLabelsProvider);
    final complaints =
        ref.watch(activeStudentComplaintsProvider).asData?.value ?? const <Complaint>[];

    return AsyncValueView(
      value: ref.watch(activeStudentRequestsProvider),
      builder: (requests) {
        final sorted = [...requests]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return PageContainer(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: () => _create(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('طلب جديد'),
              ),
            ),
            const SizedBox(height: 12),
            if (sorted.isEmpty)
              const EmptyState(icon: Icons.mail_outline, title: 'لا توجد طلبات بعد')
            else
              for (final r in sorted)
                _RequestCard(request: r, groupLabel: labels[r.requestedGroupId]),
            if (complaints.isNotEmpty) ...[
              const SizedBox(height: 8),
              SectionCard(
                title: 'الشكاوى والتنبيهات',
                child: Column(
                  children: [
                    for (final c in complaints..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          c.kind == ComplaintKind.warning
                              ? Icons.warning_amber_outlined
                              : Icons.report_outlined,
                        ),
                        title: Text(c.text),
                        subtitle: Text('${c.kind.label} • ${AppDates.dayMonth(c.createdAt)}'),
                      ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, this.groupLabel});
  final Request request;
  final String? groupLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (request.status) {
      RequestStatus.pending => theme.colorScheme.onSurfaceVariant,
      RequestStatus.approved => Colors.green,
      RequestStatus.rejected => theme.colorScheme.error,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.type.label,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(AppDates.dayMonth(request.createdAt), style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            Text(request.text),
            if (request.date != null)
              Text('اليوم: ${AppDates.dayMonth(request.date!)}', style: theme.textTheme.bodySmall),
            if (groupLabel != null)
              Text('المجموعة المطلوبة: $groupLabel', style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: color),
                const SizedBox(width: 6),
                Text(
                  request.status.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (request.reply != null) ...[
              const Divider(height: 16),
              Text('رد المدرس: ${request.reply}', style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
