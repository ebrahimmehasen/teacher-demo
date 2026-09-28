import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/models.dart';
import '../data/repository_providers.dart';
import 'session_service.dart';

/// Every child linked to the signed-in parent.
final parentLinksProvider = StreamProvider<List<ParentLink>>((ref) {
  final parentId = ref.watch(sessionProvider.select((s) => s?.user.id));
  if (parentId == null) return Stream.value(const []);
  return ref.watch(studentRepositoryProvider).watchLinksForParent(parentId);
});

final parentChildrenProvider = StreamProvider<List<User>>((ref) async* {
  final links = await ref.watch(parentLinksProvider.future);
  final ids = {for (final l in links) l.studentUserId};
  yield* ref
      .watch(userRepositoryProvider)
      .watchByIds(ids)
      .map((users) => users..sort((a, b) => a.name.compareTo(b.name)));
});
