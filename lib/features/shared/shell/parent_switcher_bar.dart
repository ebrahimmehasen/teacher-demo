import 'package:flutter/material.dart';

import 'child_switcher.dart';
import 'enrollment_switcher.dart';

/// Child switcher above the teacher/subject switcher, per the spec's
/// "child switcher + teacher/subject switcher at top" requirement.
class ParentSwitcherBar extends StatelessWidget {
  const ParentSwitcherBar({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    mainAxisSize: MainAxisSize.min,
    children: [ChildSwitcher(), EnrollmentSwitcher()],
  );
}
