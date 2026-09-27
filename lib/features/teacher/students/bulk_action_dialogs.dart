import 'package:flutter/material.dart';

import '../../../core/constants/labels.dart';
import '../../../data/models/models.dart';
import '../../../services/group_service.dart';

Future<int?> showDiscountDialog(BuildContext context, {int initial = 0}) {
  var value = initial.toDouble();
  return showDialog<int>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('تطبيق خصم'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${value.round()}%', style: Theme.of(context).textTheme.headlineMedium),
              Slider(
                value: value,
                max: 100,
                divisions: 20,
                label: '${value.round()}%',
                onChanged: (v) => setState(() => value = v),
              ),
              const Text('0% يلغي الخصم'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(value.round()),
            child: const Text('تطبيق'),
          ),
        ],
      ),
    ),
  );
}

Future<Group?> showMoveGroupDialog(
  BuildContext context, {
  required List<Group> groups,
  required Map<String, Grade> grades,
  required List<Enrollment> enrollments,
}) {
  Group? selected;
  final sorted = [...groups]
    ..sort((a, b) {
      final byGrade = (grades[a.gradeId]?.name ?? '').compareTo(grades[b.gradeId]?.name ?? '');
      return byGrade != 0 ? byGrade : a.number.compareTo(b.number);
    });
  return showDialog<Group>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('نقل إلى مجموعة'),
        content: SizedBox(
          width: 420,
          child: DropdownButtonFormField<Group>(
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'المجموعة الجديدة'),
            items: [
              for (final g in sorted)
                DropdownMenuItem(
                  value: g,
                  child: Text(
                    '${grades[g.gradeId]?.name ?? ''} – ${GroupLabels.name(g.number)} '
                    '(${GroupService.enrolledCount(g.id, enrollments)}/${g.capacity})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (g) => setState(() => selected = g),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
          FilledButton(
            onPressed: selected == null ? null : () => Navigator.of(context).pop(selected),
            child: const Text('نقل'),
          ),
        ],
      ),
    ),
  );
}

/// Rule 4 alert.
Future<void> showGroupFullAlert(BuildContext context, Group group, Grade? grade) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.group_off_outlined, color: Theme.of(context).colorScheme.error),
        title: const Text('المجموعة مكتملة'),
        content: Text(
          '${grade?.name ?? ''} – ${GroupLabels.name(group.number)} سعتها ${group.capacity} طالب '
          'ولا يوجد مكان كافٍ للطلاب المحددين.',
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('حسناً')),
        ],
      ),
    );
