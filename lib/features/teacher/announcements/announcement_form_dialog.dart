import 'package:flutter/material.dart';

import '../../../core/utils/validators.dart';
import '../../../data/models/models.dart';

class AnnouncementDraft {
  const AnnouncementDraft({required this.title, required this.body, this.gradeId});
  final String title;
  final String body;
  final String? gradeId;
}

Future<AnnouncementDraft?> showAnnouncementFormDialog(BuildContext context, List<Grade> grades) =>
    showDialog<AnnouncementDraft>(
      context: context,
      builder: (_) => _AnnouncementFormDialog(grades: grades),
    );

class _AnnouncementFormDialog extends StatefulWidget {
  const _AnnouncementFormDialog({required this.grades});
  final List<Grade> grades;

  @override
  State<_AnnouncementFormDialog> createState() => _AnnouncementFormDialogState();
}

class _AnnouncementFormDialogState extends State<_AnnouncementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  String? _gradeId;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context)
        .pop(AnnouncementDraft(title: _title.text, body: _body.text, gradeId: _gradeId));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إعلان جديد'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String?>(
                initialValue: _gradeId,
                decoration: const InputDecoration(labelText: 'الجهة المستهدفة'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('كل الطلاب')),
                  for (final g in widget.grades) DropdownMenuItem(value: g.id, child: Text(g.name)),
                ],
                onChanged: (v) => setState(() => _gradeId = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'العنوان'),
                validator: (v) => Validators.required(v, field: 'العنوان'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _body,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'النص'),
                validator: (v) => Validators.required(v, field: 'النص'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        FilledButton(onPressed: _submit, child: const Text('نشر')),
      ],
    );
  }
}
