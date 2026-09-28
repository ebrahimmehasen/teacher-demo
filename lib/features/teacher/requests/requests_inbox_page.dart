import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/labels.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/filter_dropdown.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../data/models/models.dart';
import '../../../services/complaint_service.dart';
import '../../../services/group_service.dart';
import '../../../services/session_service.dart';
import '../../../services/tenant_data.dart';
import '../students/bulk_action_dialogs.dart';
import '../../../services/request_approval_service.dart';
import 'send_complaint_dialog.dart';

class RequestsInboxPage extends ConsumerStatefulWidget {
  const RequestsInboxPage({super.key});

  @override
  ConsumerState<RequestsInboxPage> createState() => _RequestsInboxPageState();
}

class _RequestsInboxPageState extends ConsumerState<RequestsInboxPage> {
  RequestStatus? _statusFilter = RequestStatus.pending;
  final _busy = <String>{};

  Future<void> _decide(Request request, {required bool approve}) async {
    final replyController = TextEditingController();
    final grades = ref.read(gradesProvider).asData?.value ?? const <Grade>[];
    final groups = ref.read(groupsProvider).asData?.value ?? const <Group>[];
    final allEnrollments = ref.read(enrollmentsProvider).asData?.value ?? const <Enrollment>[];
    Group? targetGroup;
    if (approve && request.type == RequestType.changeGroup) {
      targetGroup = groups.where((g) => g.id == request.requestedGroupId).firstOrNull;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'قبول الطلب' : 'رفض الطلب'),
        content: TextField(
          controller: replyController,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'رد (اختياري)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy.add(request.id));
    try {
      final reply = replyController.text.trim().isEmpty ? null : replyController.text.trim();
      final now = ref.read(clockProvider)();
      final service = ref.read(requestApprovalServiceProvider);
      if (approve) {
        await service.approve(
          request,
          reply: reply,
          now: now,
          targetGroup: targetGroup,
          tenantEnrollments: allEnrollments,
        );
      } else {
        await service.reject(request, reply: reply, now: now);
      }
      if (mounted) showSuccessSnack(context, approve ? 'تم قبول الطلب' : 'تم رفض الطلب');
    } on CapacityException catch (e) {
      if (mounted) {
        await showGroupFullAlert(
          context,
          e.group,
          grades.where((g) => g.id == e.group.gradeId).firstOrNull,
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(request.id));
    }
  }

  Future<void> _sendComplaint() async {
    final students =
        (ref.read(tenantStudentsProvider).asData?.value ?? const <String, User>{}).values.toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final draft = await showSendComplaintDialog(context, students);
    if (draft == null) return;
    final session = ref.read(sessionProvider)!;
    await ref
        .read(complaintServiceProvider)
        .send(
          tenantId: session.tenantId!,
          studentId: draft.student.id,
          kind: draft.kind,
          text: draft.text,
          byUserId: session.user.id,
          now: ref.read(clockProvider)(),
        );
    if (mounted) showSuccessSnack(context, 'تم الإرسال');
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(tenantStudentsProvider).asData?.value ?? const <String, User>{};
    final labels = ref.watch(groupLabelsProvider);
    final complaints = ref.watch(complaintsProvider).asData?.value ?? const <Complaint>[];

    return AsyncValueView(
      value: ref.watch(requestsProvider),
      builder: (allRequests) {
        final requests =
            (_statusFilter == null
                    ? allRequests
                    : allRequests.where((r) => r.status == _statusFilter))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return PageContainer(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterDropdown<RequestStatus>(
                  label: 'الحالة',
                  value: _statusFilter,
                  items: {for (final s in RequestStatus.values) s: s.label},
                  onChanged: (v) => setState(() => _statusFilter = v),
                ),
                FilledButton.icon(
                  onPressed: _sendComplaint,
                  icon: const Icon(Icons.campaign_outlined),
                  label: const Text('إرسال شكوى / تنبيه'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (requests.isEmpty)
              const EmptyState(icon: Icons.mail_outline, title: 'لا توجد طلبات')
            else
              for (final r in requests)
                Card(
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
                                '${students[r.studentId]?.name ?? '—'} • ${r.type.label}',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text(
                              AppDates.dayMonth(r.createdAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(r.text),
                        if (r.date != null) Text('اليوم: ${AppDates.dayMonth(r.date!)}'),
                        if (r.requestedGroupId != null)
                          Text('المجموعة المطلوبة: ${labels[r.requestedGroupId!] ?? ''}'),
                        if (r.reply != null) ...[
                          const Divider(height: 16),
                          Text('الرد: ${r.reply}'),
                        ],
                        const SizedBox(height: 8),
                        if (r.status == RequestStatus.pending)
                          Row(
                            children: [
                              FilledButton.icon(
                                onPressed: _busy.contains(r.id)
                                    ? null
                                    : () => _decide(r, approve: true),
                                icon: const Icon(Icons.check),
                                label: const Text('قبول'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: _busy.contains(r.id)
                                    ? null
                                    : () => _decide(r, approve: false),
                                icon: const Icon(Icons.close),
                                label: const Text('رفض'),
                              ),
                            ],
                          )
                        else
                          Text(
                            r.status.label,
                            style: TextStyle(
                              color: r.status == RequestStatus.approved
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 8),
            SectionCard(
              title: 'الشكاوى والتنبيهات المرسلة',
              child: complaints.isEmpty
                  ? const Text('لم يتم إرسال أي شكاوى أو تنبيهات بعد.')
                  : Column(
                      children: [
                        for (final c
                            in complaints..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              c.kind == ComplaintKind.warning
                                  ? Icons.warning_amber_outlined
                                  : Icons.report_outlined,
                            ),
                            title: Text('${students[c.studentId]?.name ?? '—'}: ${c.text}'),
                            subtitle: Text('${c.kind.label} • ${AppDates.dayMonth(c.createdAt)}'),
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
