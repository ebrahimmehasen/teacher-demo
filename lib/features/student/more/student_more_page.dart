import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/page_container.dart';

class StudentMorePage extends StatelessWidget {
  const StudentMorePage({super.key});

  static const _items = [
    (Icons.person_outline, 'الملف الشخصي', '/student/more/profile'),
    (Icons.fact_check_outlined, 'الحضور', '/student/more/attendance'),
    (Icons.assignment_outlined, 'الدرجات والواجبات', '/student/more/grades'),
    (Icons.video_library_outlined, 'الحصص المسجلة', '/student/more/lessons'),
    (Icons.campaign_outlined, 'الإعلانات', '/student/more/announcements'),
  ];

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      maxWidth: 700,
      children: [
        for (final (icon, label, path) in _items)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(icon),
              title: Text(label),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.go(path),
            ),
          ),
      ],
    );
  }
}
