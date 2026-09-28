import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod only subscribes to a StreamProvider's underlying stream once
/// something listens to it (as `ref.watch` does inside another provider's
/// build). From a test, `container.read(provider.future)` alone never
/// resolves, so awaiting a stream provider's first value must listen first.
Future<T> awaitStream<T>(ProviderContainer container, StreamProvider<T> provider) {
  final sub = container.listen(provider, (_, _) {});
  return container.read(provider.future).whenComplete(sub.close);
}
