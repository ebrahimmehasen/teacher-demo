import 'package:flutter/material.dart';

/// Scrollable page body with responsive padding and a readable max width.
class PageContainer extends StatelessWidget {
  const PageContainer({super.key, required this.children, this.maxWidth = 1200});

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    return ListView(
      padding: EdgeInsets.all(wide ? 24 : 16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ),
      ],
    );
  }
}
