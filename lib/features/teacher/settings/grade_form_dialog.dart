import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/validators.dart';
import '../../../data/models/models.dart';

/// Returns the new/edited grade, or null when cancelled.
Future<Grade?> showGradeFormDialog(
  BuildContext context, {
  required String tenantId,
  Grade? grade,
}) => showDialog<Grade>(
  context: context,
  builder: (_) => _GradeFormDialog(tenantId: tenantId, grade: grade),
);

class _GradeFormDialog extends StatefulWidget {
  const _GradeFormDialog({required this.tenantId, this.grade});

  final String tenantId;
  final Grade? grade;

  @override
  State<_GradeFormDialog> createState() => _GradeFormDialogState();
}

class _GradeFormDialogState extends State<_GradeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.grade?.name);
  late final _price = TextEditingController(text: _num(widget.grade?.publicPrice));
  late final _capacity = TextEditingController(text: '${widget.grade?.defaultCapacity ?? 30}');
  late final _grace = TextEditingController(text: '${widget.grade?.graceDays ?? 5}');
  late int _dueDay = widget.grade?.dueDay ?? 5;

  static String _num(double? v) => v == null ? '' : v.toStringAsFixed(0);

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _capacity.dispose();
    _grace.dispose();
    super.dispose();
  }

  String? _range(String? value, int min, int max, String field) {
    final n = int.tryParse(value?.trim() ?? '');
    if (n == null) return '$field مطلوب';
    if (n < min || n > max) return '$field من $min إلى $max';
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final price = double.parse(_price.text.trim());
    final capacity = int.parse(_capacity.text.trim());
    final grace = int.parse(_grace.text.trim());
    final existing = widget.grade;
    Navigator.of(context).pop(
      existing == null
          ? Grade(
              id: const Uuid().v4(),
              tenantId: widget.tenantId,
              name: _name.text.trim(),
              publicPrice: price,
              dueDay: _dueDay,
              graceDays: grace,
              defaultCapacity: capacity,
            )
          : existing.copyWith(
              name: _name.text.trim(),
              publicPrice: price,
              dueDay: _dueDay,
              graceDays: grace,
              defaultCapacity: capacity,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final digits = [FilteringTextInputFormatter.digitsOnly];
    return AlertDialog(
      title: Text(widget.grade == null ? 'إضافة صف' : 'تعديل الصف'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'اسم الصف',
                    hintText: 'مثال: تالتة ثانوي',
                  ),
                  validator: (v) => Validators.required(v, field: 'اسم الصف'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  inputFormatters: digits,
                  decoration: const InputDecoration(
                    labelText: 'سعر الشهر (المجموعات العامة)',
                    suffixText: 'ج.م',
                  ),
                  validator: (v) => Validators.positiveNumber(v, field: 'السعر'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _dueDay,
                  decoration: const InputDecoration(labelText: 'يوم الاستحقاق من كل شهر'),
                  items: [
                    for (var d = 1; d <= 28; d++) DropdownMenuItem(value: d, child: Text('$d')),
                  ],
                  onChanged: (v) => setState(() => _dueDay = v ?? _dueDay),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _grace,
                  keyboardType: TextInputType.number,
                  inputFormatters: digits,
                  decoration: const InputDecoration(labelText: 'أيام السماح', suffixText: 'يوم'),
                  validator: (v) => _range(v, 0, 20, 'أيام السماح'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _capacity,
                  keyboardType: TextInputType.number,
                  inputFormatters: digits,
                  decoration: const InputDecoration(
                    labelText: 'السعة الافتراضية للمجموعة',
                    suffixText: 'طالب',
                  ),
                  validator: (v) => _range(v, 1, 500, 'السعة'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        FilledButton(onPressed: _save, child: const Text('حفظ')),
      ],
    );
  }
}
