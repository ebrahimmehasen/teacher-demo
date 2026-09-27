import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/labels.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../services/session_service.dart';

enum _AccountAction { toggleTheme, signOut }

class AccountMenu extends ConsumerWidget {
  const AccountMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<_AccountAction>(
      tooltip: 'الحساب',
      position: PopupMenuPosition.under,
      onSelected: (action) async {
        switch (action) {
          case _AccountAction.toggleTheme:
            ref.read(themeModeProvider.notifier).toggle();
          case _AccountAction.signOut:
            final ok = await showConfirmDialog(
              context,
              title: 'تسجيل الخروج',
              message: 'هل تريد تسجيل الخروج من الحساب؟',
              confirmLabel: 'خروج',
            );
            if (ok) ref.read(sessionProvider.notifier).signOut();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(session.user.name, style: TextStyle(color: scheme.onSurface)),
            subtitle: Text(session.role.label),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _AccountAction.toggleTheme,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            title: Text(isDark ? 'الوضع الفاتح' : 'الوضع الداكن'),
          ),
        ),
        const PopupMenuItem(
          value: _AccountAction.signOut,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout),
            title: Text('تسجيل الخروج'),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 12, start: 4),
        child: CircleAvatar(
          radius: 17,
          backgroundColor: scheme.primaryContainer,
          child: Text(
            session.user.name.characters.first,
            style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
