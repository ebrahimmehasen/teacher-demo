import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../services/parent_auth_service.dart';
import '../../../services/parent_context.dart';
import '../../../services/session_service.dart';
import '../../../services/student_context.dart';

class ManageChildrenPage extends ConsumerWidget {
  const ManageChildrenPage({super.key});

  Future<void> _addChild(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة طفل'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'كود الربط'),
            validator: (v) => Validators.required(v, field: 'كود الربط'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.of(context).pop(controller.text);
            },
            child: const Text('ربط'),
          ),
        ],
      ),
    );
    if (code == null) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    try {
      final child = await ref
          .read(parentAuthServiceProvider)
          .linkChildByCode(parent: session.user, code: code);
      await ref.read(sessionProvider.notifier).selectChild(child.id);
      if (context.mounted) showSuccessSnack(context, 'تمت إضافة ${child.name}');
    } on ParentAuthException catch (e) {
      if (context.mounted) showErrorSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeId = ref.watch(activeStudentIdProvider);
    return AsyncValueView(
      value: ref.watch(parentChildrenProvider),
      builder: (children) {
        return PageContainer(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: () => _addChild(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('إضافة طفل'),
              ),
            ),
            const SizedBox(height: 12),
            if (children.isEmpty)
              const EmptyState(
                icon: Icons.family_restroom,
                title: 'لا يوجد أبناء مرتبطون بعد',
                message: 'اطلب كود الربط من صفحة الملف الشخصي في تطبيق ابنك/ابنتك.',
              )
            else
              for (final child in children)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(child.name.characters.first)),
                    title: Text(child.name),
                    subtitle: Text(child.phone, textDirection: TextDirection.ltr),
                    trailing: child.id == activeId
                        ? const Icon(Icons.check_circle)
                        : TextButton(
                            onPressed: () =>
                                ref.read(sessionProvider.notifier).selectChild(child.id),
                            child: const Text('عرض'),
                          ),
                  ),
                ),
          ],
        );
      },
    );
  }
}
