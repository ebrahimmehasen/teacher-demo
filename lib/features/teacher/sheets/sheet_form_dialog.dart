import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/validators.dart';
import '../../../data/models/models.dart';

class SheetDraft {
  const SheetDraft({
    required this.title,
    required this.gradeId,
    required this.price,
    required this.printedQty,
    required this.announce,
  });
  final String title;
  final String gradeId;
  final double price;
  final int printedQty;
  final bool announce;
}

Future<SheetDraft?> showSheetFormDialog(BuildContext context, List<Grade> grades) =>
    showDialog<SheetDraft>(
      context: context,
      builder: (_) => _SheetFormDialog(grades: grades),
    );

class _SheetFormDialog extends StatefulWidget {
  const _SheetFormDialog({required this.grades});
  final List<Grade> grades;

  @override
  State<_SheetFormDialog> createState() => _SheetFormDialogState();
}

class _SheetFormDialogState extends State<_SheetFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _price = TextEditingController();
  final _qty = TextEditingController();
  String? _gradeId;
  var _announce = false;

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _qty.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      SheetDraft(
        title: _title.text.trim(),
        gradeId: _gradeId!,
        price: double.parse(_price.text),
        printedQty: int.parse(_qty.text),
        announce: _announce,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final digits = [FilteringTextInputFormatter.digitsOnly];
    return AlertDialog(
      title: const Text('إضافة مذكرة / كتاب'),
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
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                inputFormatters: digits,
                decoration: const InputDecoration(labelText: 'السعر', suffixText: 'ج.م'),
                validator: (v) => Validators.positiveNumber(v, field: 'السعر'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qty,
                keyboardType: TextInputType.number,
                inputFormatters: digits,
                decoration: const InputDecoration(labelText: 'العدد المطبوع', suffixText: 'نسخة'),
                validator: (v) => Validators.positiveNumber(v, field: 'العدد'),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _announce,
                onChanged: (v) => setState(() => _announce = v ?? false),
                title: const Text('نشر إعلان للطلاب بتوفر المذكرة'),
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
