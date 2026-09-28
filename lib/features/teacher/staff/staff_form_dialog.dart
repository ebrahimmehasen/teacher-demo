import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/labels.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/enums.dart';

class StaffDraft {
  const StaffDraft({
    required this.name,
    required this.phone,
    required this.type,
    required this.permissions,
  });
  final String name;
  final String phone;
  final StaffType type;
  final Set<Permission> permissions;
}

Future<StaffDraft?> showStaffFormDialog(BuildContext context) =>
    showDialog<StaffDraft>(context: context, builder: (_) => const _StaffFormDialog());

class _StaffFormDialog extends StatefulWidget {
  const _StaffFormDialog();

  @override
  State<_StaffFormDialog> createState() => _StaffFormDialogState();
}

class _StaffFormDialogState extends State<_StaffFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  var _type = StaffType.assistant;
  final _permissions = <Permission>{...Permission.values};

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_permissions.isEmpty) return;
    Navigator.of(context).pop(
      StaffDraft(
        name: _name.text,
        phone: _phone.text,
        type: _type,
        permissions: Set.of(_permissions),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة مساعد'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'الاسم'),
                  validator: (v) => Validators.required(v, field: 'الاسم'),
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
                SegmentedButton<StaffType>(
                  segments: [
                    for (final t in StaffType.values) ButtonSegment(value: t, label: Text(t.label)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
                const SizedBox(height: 16),
                Text('الصلاحيات', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in Permission.values)
                      FilterChip(
                        label: Text(p.label),
                        selected: _permissions.contains(p),
                        onSelected: (v) =>
                            setState(() => v ? _permissions.add(p) : _permissions.remove(p)),
                      ),
                  ],
                ),
              ],
            ),
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
