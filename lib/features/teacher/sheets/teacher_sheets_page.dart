import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/status_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../data/models/models.dart';
import '../../../data/repository_providers.dart';
import '../../../services/announcement_service.dart';
import '../../../services/session_service.dart';
import '../../../services/sheet_service.dart';
import '../../../services/tenant_data.dart';
import 'sheet_form_dialog.dart';

class TeacherSheetsPage extends ConsumerWidget {
  const TeacherSheetsPage({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final grades = ref.read(gradesProvider).asData?.value ?? const <Grade>[];
    if (grades.isEmpty) {
      showErrorSnack(context, 'أضف صفاً أولاً من الإعدادات');
      return;
    }
    final draft = await showSheetFormDialog(context, grades);
    if (draft == null) return;
    final session = ref.read(sessionProvider)!;
    final now = ref.read(clockProvider)();

    final sheet = await ref
        .read(sheetRepositoryProvider)
        .addSheet(
          Sheet(
            id: const Uuid().v4(),
            tenantId: session.tenantId!,
            gradeId: draft.gradeId,
            title: draft.title,
            price: draft.price,
            printedQty: draft.printedQty,
            createdAt: now,
          ),
        );

    if (draft.announce) {
      final grade = grades.firstWhere((g) => g.id == draft.gradeId);
      final enrollments = ref.read(enrollmentsProvider).asData?.value ?? const <Enrollment>[];
      final groups = (ref.read(groupsProvider).asData?.value ?? const <Group>[])
          .where((g) => g.gradeId == draft.gradeId)
          .map((g) => g.id)
          .toSet();
      await ref
          .read(announcementServiceProvider)
          .create(
            tenantId: session.tenantId!,
            title: 'مذكرة جديدة',
            body: '${sheet.title} متاحة الآن لطلاب ${grade.name} عند المساعد.',
            gradeId: draft.gradeId,
            targetStudentIds: {
              for (final e in enrollments)
                if (e.active && groups.contains(e.groupId)) e.studentId,
            },
            now: now,
          );
    }
    if (context.mounted) showSuccessSnack(context, 'تمت إضافة "${draft.title}"');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradeNames = {
      for (final g in ref.watch(gradesProvider).asData?.value ?? const <Grade>[]) g.id: g.name,
    };
    final sales = ref.watch(sheetSalesProvider).asData?.value ?? const <SheetSale>[];

    return AsyncValueView(
      value: ref.watch(sheetsProvider),
      builder: (sheets) {
        final sorted = [...sheets]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return PageContainer(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: () => _add(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('إضافة مذكرة'),
              ),
            ),
            const SizedBox(height: 12),
            if (sorted.isEmpty)
              const EmptyState(icon: Icons.menu_book_outlined, title: 'لا توجد مذكرات بعد')
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingTextStyle: const TextStyle(fontWeight: FontWeight.w700),
                    columns: const [
                      DataColumn(label: Text('العنوان')),
                      DataColumn(label: Text('الصف')),
                      DataColumn(label: Text('السعر')),
                      DataColumn(label: Text('المطبوع')),
                      DataColumn(label: Text('المباع')),
                      DataColumn(label: Text('المتبقي')),
                    ],
                    rows: [
                      for (final s in sorted)
                        DataRow(
                          cells: [
                            DataCell(Text(s.title)),
                            DataCell(Text(gradeNames[s.gradeId] ?? '')),
                            DataCell(Text(Money.format(s.price))),
                            DataCell(Text('${s.printedQty}')),
                            DataCell(Text('${SheetStock.sold(s.id, sales)}')),
                            DataCell(_RemainingCell(remaining: SheetStock.remaining(s, sales))),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RemainingCell extends StatelessWidget {
  const _RemainingCell({required this.remaining});
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final low = SheetStock.isLow(remaining);
    return Text(
      '$remaining',
      style: TextStyle(
        color: low ? StatusColors.of(context).danger : null,
        fontWeight: low ? FontWeight.w700 : null,
      ),
    );
  }
}
