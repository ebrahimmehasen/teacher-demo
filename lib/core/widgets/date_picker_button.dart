import 'package:flutter/material.dart';

import '../utils/date_utils.dart';

class DatePickerButton extends StatelessWidget {
  const DatePickerButton({
    super.key,
    required this.date,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
  });

  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: firstDate ?? DateTime(date.year - 1),
          lastDate: lastDate ?? DateTime(date.year + 1),
        );
        if (picked != null) onChanged(AppDates.dateOnly(picked));
      },
      icon: const Icon(Icons.event_outlined),
      label: Text(AppDates.dayMonth(date)),
    );
  }
}
