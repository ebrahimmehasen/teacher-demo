import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/page_container.dart';

class ParentMorePage extends StatelessWidget {
  const ParentMorePage({super.key});

  static const _items = [
    (Icons.family_restroom, 'إدارة الأبناء', '/parent/more/children'),
    (Icons.calendar_month_outlined, 'الجدول', '/parent/more/schedule'),
    (Icons.bar_chart_outlined, 'التقرير', '/parent/more/report'),
    (Icons.receipt_long_outlined, 'المدفوعات', '/parent/more/payments'),
    (Icons.video_library_outlined, 'الحصص المسجلة', '/parent/more/lessons'),
    (Icons.campaign_outlined, 'الإعلانات', '/parent/more/announcements'),
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
