import 'package:flutter/material.dart';

import '../theme/status_colors.dart';

void showSuccessSnack(BuildContext context, String message) =>
    _show(context, message, Icons.check_circle, StatusColors.of(context).success);

void showErrorSnack(BuildContext context, String message) =>
    _show(context, message, Icons.error, Theme.of(context).colorScheme.error);

void _show(BuildContext context, String message, IconData icon, Color color) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
