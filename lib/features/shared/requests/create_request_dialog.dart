import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/labels.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/models.dart';
import '../../../services/student_context.dart';
import '../../../services/tenant_data.dart';

class RequestDraft {
  const RequestDraft({required this.type, required this.text, this.date, this.requestedGroupId});
  final RequestType type;
  final String text;
  final DateTime? date;
  final String? requestedGroupId;
}

/// Returns the filled-in request, or null when cancelled.
Future<RequestDraft?> showCreateRequestDialog(BuildContext context) =>
    showDialog<RequestDraft>(context: context, builder: (_) => const _CreateRequestDialog());

class _CreateRequestDialog extends ConsumerStatefulWidget {
  const _CreateRequestDialog();

  @override
  ConsumerState<_CreateRequestDialog> createState() => _CreateRequestDialogState();
}

class _CreateRequestDialogState extends ConsumerState<_CreateRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _text = TextEditingController();
  var _type = RequestType.absence;
  DateTime? _date;
  String? _requestedGroupId;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_type == RequestType.changeGroup && _requestedGroupId == null) return;
    Navigator.of(context).pop(
      RequestDraft(type: _type, text: _text.text, date: _date, requestedGroupId: _requestedGroupId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myGroups = ref.watch(activeStudentGroupsProvider);
    final myGroupIds = {for (final g in myGroups) g.id};
    final myGradeIds = {for (final g in myGroups) g.gradeId};
    final labels = ref.watch(groupLabelsProvider);
    final targetGroups = (ref.watch(groupsProvider).asData?.value ?? const <Group>[])
        .where((g) => myGradeIds.contains(g.gradeId) && !myGroupIds.contains(g.id))
        .toList();

    return AlertDialog(
      title: const Text('طلب جديد'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<RequestType>(
                  segments: [
                    for (final t in RequestType.values)
                      ButtonSegment(value: t, label: Text(t.label)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
                const SizedBox(height: 16),
                if (_type == RequestType.absence)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final today = ref.read(clockProvider)();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date ?? today,
                        firstDate: today,
                        lastDate: today.add(const Duration(days: 60)),
                      );
                      if (picked != null) setState(() => _date = AppDates.dateOnly(picked));
                    },
                    icon: const Icon(Icons.event_outlined),
                    label: Text(_date == null ? 'اختر يوم الغياب' : AppDates.dayMonth(_date!)),
                  ),
                if (_type == RequestType.changeGroup)
                  DropdownButtonFormField<String>(
                    initialValue: _requestedGroupId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'المجموعة المطلوبة'),
                    items: [
                      for (final g in targetGroups)
                        DropdownMenuItem(value: g.id, child: Text(labels[g.id] ?? '')),
                    ],
                    onChanged: (v) => setState(() => _requestedGroupId = v),
                    validator: (v) => v == null ? 'اختر المجموعة' : null,
                  ),
                if (_type != RequestType.other) const SizedBox(height: 12),
                TextFormField(
                  controller: _text,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'التفاصيل'),
                  validator: (v) => Validators.required(v, field: 'التفاصيل'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        FilledButton(onPressed: _submit, child: const Text('إرسال')),
      ],
    );
  }
}
