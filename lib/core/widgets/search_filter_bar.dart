import 'package:flutter/material.dart';

/// Search field followed by filter controls. On phones the filters sit in one
/// horizontally scrolling row under the search field.
class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({
    super.key,
    required this.onSearch,
    this.hint = 'بحث بالاسم أو الموبايل',
    this.filters = const [],
  });

  final ValueChanged<String> onSearch;
  final String hint;
  final List<Widget> filters;

  @override
  Widget build(BuildContext context) {
    final search = TextField(
      onChanged: onSearch,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        isDense: true,
      ),
    );

    if (MediaQuery.sizeOf(context).width < 600) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          if (filters.isNotEmpty) ...[
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // Room for the floating field labels, which the scroll view would clip.
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  for (final f in filters)
                    Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: f),
                ],
              ),
            ),
          ],
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 360), child: search),
        ...filters,
      ],
    );
  }
}
