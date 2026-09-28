import 'package:flutter/material.dart';

import '../../../core/widgets/status_chip.dart';
import '../../../services/report_service.dart';

extension StudentLevelUi on StudentLevel {
  StatusTone get tone => switch (this) {
    StudentLevel.excellent => StatusTone.success,
    StudentLevel.veryGood => StatusTone.info,
    StudentLevel.good => StatusTone.warning,
    StudentLevel.needsFollowUp => StatusTone.danger,
  };

  IconData get icon => switch (this) {
    StudentLevel.excellent => Icons.star,
    StudentLevel.veryGood => Icons.thumb_up,
    StudentLevel.good => Icons.trending_up,
    StudentLevel.needsFollowUp => Icons.priority_high,
  };
}

class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.level});
  final StudentLevel level;

  @override
  Widget build(BuildContext context) {
    final color = toneColor(context, level.tone);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(level.icon, color: color),
          const SizedBox(width: 8),
          Text(
            level.label,
            style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
