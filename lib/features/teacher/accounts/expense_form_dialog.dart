import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/labels.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/enums.dart';

class ExpenseDraft {
  const ExpenseDraft({
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.note,
  });
  final String title;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  final String? note;
}

Future<ExpenseDraft?> showExpenseFormDialog(
  BuildContext context, {
  required DateTime initialDate,
}) => showDialog<ExpenseDraft>(
  context: context,
  builder: (_) => _ExpenseFormDialog(initialDate: initialDate),
);

class _ExpenseFormDialog extends StatefulWidget {
  const _ExpenseFormDialog({required this.initialDate});
  final DateTime initialDate;

  @override
  State<_ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<_ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  var _category = ExpenseCategory.other;
  late var _date = widget.initialDate;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      ExpenseDraft(
        title: _title.text.trim(),
        category: _category,
        amount: double.parse(_amount.text),
        date: _date,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('مصروف جديد'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'البند'),
                validator: (v) => Validators.required(v, field: 'البند'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ExpenseCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'التصنيف'),
                items: [
                  for (final c in ExpenseCategory.values)
                    DropdownMenuItem(value: c, child: Text(c.label)),
                ],
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'المبلغ', suffixText: 'ج.م'),
                validator: (v) => Validators.positiveNumber(v, field: 'المبلغ'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(_date.year - 1),
                    lastDate: DateTime(_date.year + 1),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                icon: const Icon(Icons.event_outlined),
                label: Text(AppDates.dayMonth(_date)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)'),
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
