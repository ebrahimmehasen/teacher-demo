import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../services/session_service.dart';
import '../../../services/student_context.dart';

class StudentProfilePage extends ConsumerWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenant = ref.watch(currentTenantProvider).asData?.value;
    return AsyncValueView(
      value: ref.watch(activeStudentProvider),
      builder: (student) {
        if (student == null) return const SizedBox.shrink();
        final profile = ref.watch(activeStudentProfileProvider).asData?.value;
        final theme = Theme.of(context);

        return PageContainer(
          maxWidth: 600,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                child: Text(student.name.characters.first, style: theme.textTheme.headlineMedium),
              ),
            ),
            const SizedBox(height: 12),
            Text(student.name, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
            if (tenant != null)
              Text(
                '${tenant.teacherName} – ${tenant.subject}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 20),
            SectionCard(
              title: 'البيانات',
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.phone_iphone),
                    title: const Text('رقم الموبايل'),
                    subtitle: Text(student.phone, textDirection: TextDirection.ltr),
                  ),
                  if (profile != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.school_outlined),
                      title: const Text('الصف الدراسي'),
                      subtitle: Text(profile.schoolYear),
                    ),
                ],
              ),
            ),
            if (profile != null) ...[
              const SizedBox(height: 16),
              SectionCard(
                title: 'كود ربط ولي الأمر',
                subtitle: 'شارك هذا الكود مع ولي أمرك ليتمكن من متابعتك',
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile.parentLinkCode,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          letterSpacing: 6,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'نسخ',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: profile.parentLinkCode));
                        showSuccessSnack(context, 'تم نسخ الكود');
                      },
                      icon: const Icon(Icons.copy),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
