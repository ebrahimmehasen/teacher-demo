import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/validators.dart';
import '../../../data/models/models.dart';
import '../../shared/students/student_picker_dialog.dart';

class ComplaintDraft {
  const ComplaintDraft({required this.student, required this.kind, required this.text});
  final User student;
  final ComplaintKind kind;
  final String text;
}

Future<ComplaintDraft?> showSendComplaintDialog(BuildContext context, List<User> students) =>
    showDialog<ComplaintDraft>(
      context: context,
      builder: (_) => _SendComplaintDialog(students: students),
    );

class _SendComplaintDialog extends ConsumerStatefulWidget {
  const _SendComplaintDialog({required this.students});
  final List<User> students;

  @override
  ConsumerState<_SendComplaintDialog> createState() => _SendComplaintDialogState();
}

class _SendComplaintDialogState extends ConsumerState<_SendComplaintDialog> {
  final _formKey = GlobalKey<FormState>();
  final _text = TextEditingController();
  User? _student;
  var _kind = ComplaintKind.complaint;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickStudent() async {
    final picked = await showStudentPicker(
      context,
      students: widget.students,
      title: 'اختر الطالب',
    );
    if (picked != null) setState(() => _student = picked);
  }

  void _submit() {
    if (_student == null || !_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(ComplaintDraft(student: _student!, kind: _kind, text: _text.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إرسال شكوى / تنبيه'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: _pickStudent,
                icon: const Icon(Icons.person_search_outlined),
                label: Text(_student?.name ?? 'اختر الطالب'),
              ),
              const SizedBox(height: 12),
              SegmentedButton<ComplaintKind>(
                segments: const [
                  ButtonSegment(value: ComplaintKind.complaint, label: Text('شكوى لولي الأمر')),
                  ButtonSegment(value: ComplaintKind.warning, label: Text('تنبيه للطالب')),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.first),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _text,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'النص'),
                validator: (v) => Validators.required(v, field: 'النص'),
              ),
            ],
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
