import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'empty_state.dart';
import 'loading_skeleton.dart';

class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({super.key, required this.value, required this.builder, this.loading});

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: builder,
      loading: () => loading ?? const LoadingSkeleton(),
      error: (error, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'حدث خطأ أثناء التحميل',
        message: error.toString(),
      ),
    );
  }
}
