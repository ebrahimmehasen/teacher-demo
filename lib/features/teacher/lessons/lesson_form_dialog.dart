import 'package:flutter/material.dart';

import '../../../core/utils/validators.dart';
import '../../../data/models/models.dart';

class LessonDraft {
  const LessonDraft({required this.title, required this.gradeId, required this.driveUrl});
  final String title;
  final String gradeId;
  final String driveUrl;
}

Future<LessonDraft?> showLessonFormDialog(BuildContext context, List<Grade> grades) =>
    showDialog<LessonDraft>(
      context: context,
      builder: (_) => _LessonFormDialog(grades: grades),
    );

class _LessonFormDialog extends StatefulWidget {
  const _LessonFormDialog({required this.grades});
  final List<Grade> grades;

  @override
  State<_LessonFormDialog> createState() => _LessonFormDialogState();
}

class _LessonFormDialogState extends State<_LessonFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _url = TextEditingController();
  String? _gradeId;

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(
      context,
    ).pop(LessonDraft(title: _title.text.trim(), gradeId: _gradeId!, driveUrl: _url.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة حصة مسجلة'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'عنوان الحصة'),
                validator: (v) => Validators.required(v, field: 'العنوان'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gradeId,
                decoration: const InputDecoration(labelText: 'الصف'),
                items: [
                  for (final g in widget.grades) DropdownMenuItem(value: g.id, child: Text(g.name)),
                ],
                onChanged: (v) => setState(() => _gradeId = v),
                validator: (v) => v == null ? 'اختر الصف' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _url,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: 'رابط Drive'),
                validator: (v) {
                  final uri = Uri.tryParse(v?.trim() ?? '');
                  if (uri == null || !uri.isAbsolute) return 'رابط غير صحيح';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        FilledButton(onPressed: _submit, child: const Text('إضافة')),
      ],
    );
  }
}
