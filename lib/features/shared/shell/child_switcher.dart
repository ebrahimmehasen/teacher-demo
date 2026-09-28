import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/models.dart';
import '../../../services/parent_context.dart';
import '../../../services/session_service.dart';
import '../../../services/student_context.dart';

/// Lets a parent with more than one child switch which one the screens show.
class ChildSwitcher extends ConsumerWidget {
  const ChildSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(parentChildrenProvider).asData?.value ?? const <User>[];
    if (children.length < 2) return const SizedBox.shrink();

    final activeId = ref.watch(activeStudentIdProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
      child: SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            for (final child in children)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChoiceChip(
                  avatar: CircleAvatar(
                    radius: 12,
                    child: Text(child.name.characters.first, style: theme.textTheme.labelSmall),
                  ),
                  label: Text(child.name),
                  selected: child.id == activeId,
                  onSelected: (_) => ref.read(sessionProvider.notifier).selectChild(child.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
