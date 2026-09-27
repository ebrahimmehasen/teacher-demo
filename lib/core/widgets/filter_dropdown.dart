import 'package:flutter/material.dart';

/// Compact dropdown whose first option ("الكل" by default) means no filter (null).
class FilterDropdown<T> extends StatelessWidget {
  const FilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.width = 180,
    this.allLabel = 'الكل',
  });

  final String label;
  final T? value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;
  final double width;

  /// Null hides the "all" option, making a choice mandatory.
  final String? allLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<T?>(
        key: ValueKey('$label-$value-${items.length}'),
        initialValue: items.containsKey(value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, isDense: true),
        items: [
          if (allLabel != null) DropdownMenuItem<T?>(value: null, child: Text(allLabel!)),
          for (final e in items.entries)
            DropdownMenuItem<T?>(
              value: e.key,
              child: Text(e.value, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
