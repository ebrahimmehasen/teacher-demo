import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/models.dart';

class AssessmentDraft {
  const AssessmentDraft({
    required this.title,
    required this.gradeId,
    required this.type,
    required this.date,
    this.maxScore,
  });
  final String title;
  final String gradeId;
  final AssessmentType type;
  final DateTime date;
  final double? maxScore;
}

Future<AssessmentDraft?> showAssessmentFormDialog(
  BuildContext context,
  List<Grade> grades,
  DateTime today,
) => showDialog<AssessmentDraft>(
  context: context,
  builder: (_) => _AssessmentFormDialog(grades: grades, today: today),
);

class _AssessmentFormDialog extends StatefulWidget {
  const _AssessmentFormDialog({required this.grades, required this.today});
  final List<Grade> grades;
  final DateTime today;

  @override
  State<_AssessmentFormDialog> createState() => _AssessmentFormDialogState();
}

class _AssessmentFormDialogState extends State<_AssessmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _maxScore = TextEditingController();
  String? _gradeId;
  var _type = AssessmentType.homework;
  late var _date = widget.today;

  @override
  void dispose() {
    _title.dispose();
    _maxScore.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final max = _type == AssessmentType.exam
        ? double.tryParse(_maxScore.text)
        : double.tryParse(_maxScore.text);
    Navigator.of(context).pop(
      AssessmentDraft(
        title: _title.text.trim(),
        gradeId: _gradeId!,
        type: _type,
        date: _date,
        maxScore: max,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('واجب / امتحان جديد'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<AssessmentType>(
                segments: const [
                  ButtonSegment(value: AssessmentType.homework, label: Text('واجب')),
                  ButtonSegment(value: AssessmentType.exam, label: Text('امتحان')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'العنوان'),
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
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: widget.today.subtract(const Duration(days: 365)),
                    lastDate: widget.today.add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                icon: const Icon(Icons.event_outlined),
                label: Text(AppDates.dayMonth(_date)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxScore,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'الدرجة النهائية (اختياري)',
                  helperText: _type == AssessmentType.homework
                      ? 'اتركها فارغة لتسليم فقط (✓/✗)'
                      : null,
                ),
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
