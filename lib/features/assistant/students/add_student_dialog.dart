import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/validators.dart';
import '../../../data/models/models.dart';
import '../../../services/admission_service.dart';
import '../../../services/group_service.dart';
import '../../../services/session_service.dart';
import '../../../services/tenant_data.dart';
import '../../teacher/students/bulk_action_dialogs.dart';

/// Returns the admission result, or null when cancelled.
Future<AdmissionResult?> showAddStudentDialog(BuildContext context) =>
    showDialog<AdmissionResult>(context: context, builder: (_) => const _AddStudentDialog());

class _AddStudentDialog extends ConsumerStatefulWidget {
  const _AddStudentDialog();

  @override
  ConsumerState<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends ConsumerState<_AddStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _parentName = TextEditingController();
  final _parentPhone = TextEditingController();
  String? _gradeId;
  String? _groupId;
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _parentName.dispose();
    _parentPhone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final groups = ref.read(groupsProvider).asData?.value ?? const <Group>[];
    final grades = ref.read(gradesProvider).asData?.value ?? const <Grade>[];
    final group = groups.firstWhere((g) => g.id == _groupId);
    final grade = grades.firstWhere((g) => g.id == group.gradeId);
    final tenantId = ref.read(sessionProvider)!.tenantId!;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(admissionServiceProvider)
          .admit(
            tenantId: tenantId,
            name: _name.text,
            phone: _phone.text,
            group: group,
            schoolYear: grade.name,
            tenantEnrollments: ref.read(enrollmentsProvider).asData?.value ?? const [],
            now: ref.read(clockProvider)(),
            parentName: _parentName.text,
            parentPhone: _parentPhone.text,
          );
      if (mounted) Navigator.of(context).pop(result);
    } on CapacityException catch (e) {
      if (mounted) await showGroupFullAlert(context, e.group, grade);
    } on AdmissionException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grades = ref.watch(gradesProvider).asData?.value ?? const <Grade>[];
    final groups = ref.watch(groupsProvider).asData?.value ?? const <Group>[];
    final enrollments = ref.watch(enrollmentsProvider).asData?.value ?? const <Enrollment>[];
    final labels = ref.watch(groupLabelsProvider);
    final gradeGroups = groups.where((g) => g.gradeId == _gradeId).toList();
    final digits = [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)];

    return AlertDialog(
      title: const Text('إضافة طالب'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'اسم الطالب رباعي'),
                  validator: (v) => Validators.required(v, field: 'الاسم'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  inputFormatters: digits,
                  decoration: const InputDecoration(labelText: 'موبايل الطالب'),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _gradeId,
                  decoration: const InputDecoration(labelText: 'الصف'),
                  items: [
                    for (final g in grades) DropdownMenuItem(value: g.id, child: Text(g.name)),
                  ],
                  onChanged: (v) => setState(() {
                    _gradeId = v;
                    _groupId = null;
                  }),
                  validator: (v) => v == null ? 'اختر الصف' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(_gradeId),
                  initialValue: _groupId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'المجموعة'),
                  items: [
                    for (final g in gradeGroups)
                      DropdownMenuItem(
                        value: g.id,
                        child: Text(
                          '${labels[g.id] ?? ''} (${GroupService.enrolledCount(g.id, enrollments)}/${g.capacity})'
                          '${GroupService.hasRoom(g, enrollments) ? '' : ' – مكتملة'}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _groupId = v),
                  validator: (v) => v == null ? 'اختر المجموعة' : null,
                ),
                const SizedBox(height: 20),
                Text('ولي الأمر (اختياري)', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _parentName,
                  decoration: const InputDecoration(labelText: 'اسم ولي الأمر'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _parentPhone,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  inputFormatters: digits,
                  decoration: const InputDecoration(
                    labelText: 'موبايل ولي الأمر',
                    helperText: 'لو الرقم مسجل بالفعل سيتم ربط الطالب بحسابه',
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? null : Validators.phone(v),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('إضافة'),
        ),
      ],
    );
  }
}

/// Shows the new account's credentials and the parent link code.
Future<void> showAdmissionSummary(BuildContext context, AdmissionResult result) => showDialog<void>(
  context: context,
  builder: (context) {
    final theme = Theme.of(context);
    return AlertDialog(
      icon: Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 40),
      title: const Text('تمت إضافة الطالب'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('بيانات دخول الطالب:', style: theme.textTheme.titleSmall),
          SelectableText(
            'الموبايل: ${result.student.phone}\nكلمة المرور: ${AdmissionService.defaultPassword}',
          ),
          const SizedBox(height: 12),
          Text('كود ربط ولي الأمر:', style: theme.textTheme.titleSmall),
          Row(
            children: [
              SelectableText(
                result.linkCode,
                style: theme.textTheme.headlineSmall?.copyWith(
                  letterSpacing: 4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                tooltip: 'نسخ',
                onPressed: () => Clipboard.setData(ClipboardData(text: result.linkCode)),
                icon: const Icon(Icons.copy),
              ),
            ],
          ),
          if (result.parent != null) ...[
            const SizedBox(height: 12),
            Text(
              result.parentCreated
                  ? 'تم إنشاء حساب لولي الأمر (${result.parent!.phone}) بكلمة المرور ${AdmissionService.defaultPassword}.'
                  : 'تم ربط الطالب بحساب ولي الأمر الموجود (${result.parent!.name}).',
            ),
          ],
        ],
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('تم')),
      ],
    );
  },
);
