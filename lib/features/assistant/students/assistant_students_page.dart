import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/labels.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/search_filter_bar.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/models.dart';
import '../../../services/admission_service.dart';
import '../../shared/students/student_rows.dart';
import 'add_student_dialog.dart';

class AssistantStudentsPage extends ConsumerStatefulWidget {
  const AssistantStudentsPage({super.key});

  @override
  ConsumerState<AssistantStudentsPage> createState() => _AssistantStudentsPageState();
}

class _AssistantStudentsPageState extends ConsumerState<AssistantStudentsPage> {
  var _query = '';

  Future<void> _add() async {
    final result = await showAddStudentDialog(context);
    if (result == null || !mounted) return;
    await showAdmissionSummary(context, result);
  }

  Future<void> _linkParent(User student) async {
    final phone = TextEditingController();
    final name = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ربط ولي أمر – ${student.name}'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: const InputDecoration(labelText: 'موبايل ولي الأمر'),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'اسم ولي الأمر',
                    helperText: 'مطلوب فقط لو الرقم غير مسجل',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.of(context).pop(true);
            },
            child: const Text('ربط'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final (parent, created) = await ref
          .read(admissionServiceProvider)
          .linkParent(student: student, parentPhone: phone.text, parentName: name.text);
      if (!mounted) return;
      showSuccessSnack(
        context,
        created
            ? 'تم إنشاء حساب ولي الأمر (${parent.phone}) وربطه – كلمة المرور ${AdmissionService.defaultPassword}'
            : 'تم ربط ${student.name} بحساب ${parent.name}',
      );
    } on AdmissionException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(tenantProfilesProvider).asData?.value ?? const {};
    final links = ref.watch(tenantParentLinksProvider).asData?.value ?? const <ParentLink>[];

    return AsyncValueView(
      value: ref.watch(studentRowsProvider),
      builder: (allRows) {
        final rows = allRows.where(StudentFilter(query: _query).matches).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SearchFilterBar(
                onSearch: (q) => setState(() => _query = q),
                filters: [
                  FilledButton.icon(
                    onPressed: _add,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('إضافة طالب'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('${rows.length} طالب', style: Theme.of(context).textTheme.titleSmall),
            ),
            const Divider(),
            Expanded(
              child: rows.isEmpty
                  ? const EmptyState(icon: Icons.search_off, title: 'لا يوجد طلاب مطابقون')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: rows.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final r = rows[i];
                        final parents = links.where((l) => l.studentUserId == r.student.id).length;
                        final code = profiles[r.student.id]?.parentLinkCode;
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Text(r.student.name.characters.first)),
                            title: Text(r.student.name),
                            subtitle: Text(
                              '${r.grade.name} – ${GroupLabels.name(r.group.number)} • ${r.student.phone}'
                              '${code == null ? '' : ' • كود الربط $code'}\n'
                              '${parents == 0 ? 'لا يوجد ولي أمر مرتبط' : 'أولياء الأمور: $parents'}',
                            ),
                            isThreeLine: true,
                            trailing: Wrap(
                              spacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                StatusChip.payment(r.billing.status),
                                IconButton(
                                  tooltip: 'ربط ولي أمر',
                                  onPressed: () => _linkParent(r.student),
                                  icon: const Icon(Icons.family_restroom),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
