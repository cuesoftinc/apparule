import 'dart:async';

import 'package:apparule/src/features/feed/data/post_repository_fake.dart';
import 'package:apparule/src/features/profile/presentation/follow_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pending_morph.dart';
import '../../../../helpers/pump_app.dart';

/// The pending-future morph contract over the optimistic
/// FollowGraphController (CLASS 2): the repository future NEVER resolves
/// during the test, yet one frame after the tap the row already reads
/// "Following" with no skeleton anywhere. This is the recipe the lanes
/// replay per social surface (D18/D19/D58).
void main() {
  testWidgets('the follow morph lands one frame after the tap, while the '
      'repository future is still pending', (tester) async {
    final gate = Completer<void>();
    await tester.pumpApp(
      const Scaffold(body: Center(child: _FollowProbe('tunde.o'))),
      postRepository: _GatedPostRepository(gate),
    );
    expect(find.text('Follow'), findsOneWidget);

    await expectMorphsWhilePending(
      tester,
      trigger: find.text('Follow'),
      expectMorphed: () => expect(find.text('Following'), findsOneWidget),
    );
  });
}

/// A minimal optimistic surface: renders the controller's local graph
/// overlay, exactly the way lane surfaces will
/// (`overlay[username] ?? serverValue`).
class _FollowProbe extends ConsumerWidget {
  const _FollowProbe(this.username);

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final following =
        ref.watch(followGraphControllerProvider)[username] ?? false;
    return TextButton(
      onPressed: () => unawaited(
        ref
            .read(followGraphControllerProvider.notifier)
            .setFollow(username, follow: !following),
      ),
      child: Text(following ? 'Following' : 'Follow'),
    );
  }
}

/// The gate: `setFollow` blocks on a completer the test never completes.
class _GatedPostRepository extends PostRepositoryFake {
  _GatedPostRepository(this._gate)
    : super(now: () => DateTime.utc(2026, 7, 22, 12));

  final Completer<void> _gate;

  @override
  Future<void> setFollow(String username, {required bool follow}) =>
      _gate.future;
}
