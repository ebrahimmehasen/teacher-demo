import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/labels.dart';
import '../../core/utils/validators.dart';
import '../../data/models/enums.dart';

class TeacherDraft {
  const TeacherDraft({
    required this.teacherName,
    required this.subject,
    required this.phone,
    required this.plan,
  });
  final String teacherName;
  final String subject;
  final String phone;
  final SubscriptionPlan plan;
}

Future<TeacherDraft?> showAddTeacherDialog(BuildContext context) =>
    showDialog<TeacherDraft>(context: context, builder: (_) => const _AddTeacherDialog());

class _AddTeacherDialog extends StatefulWidget {
  const _AddTeacherDialog();

  @override
  State<_AddTeacherDialog> createState() => _AddTeacherDialogState();
}

class _AddTeacherDialogState extends State<_AddTeacherDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _subject = TextEditingController();
  final _phone = TextEditingController();
  var _plan = SubscriptionPlan.basic;

  @override
  void dispose() {
    _name.dispose();
    _subject.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      TeacherDraft(
        teacherName: _name.text.trim(),
        subject: _subject.text.trim(),
        phone: _phone.text.trim(),
        plan: _plan,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة مدرس'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'اسم المدرس'),
                validator: (v) => Validators.required(v, field: 'الاسم'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subject,
                decoration: const InputDecoration(labelText: 'المادة'),
                validator: (v) => Validators.required(v, field: 'المادة'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: const InputDecoration(labelText: 'رقم الموبايل'),
                validator: Validators.phone,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SubscriptionPlan>(
                initialValue: _plan,
                decoration: const InputDecoration(labelText: 'الباقة'),
                items: [
                  for (final p in SubscriptionPlan.values)
                    DropdownMenuItem(value: p, child: Text(p.label)),
                ],
                onChanged: (v) => setState(() => _plan = v ?? _plan),
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
