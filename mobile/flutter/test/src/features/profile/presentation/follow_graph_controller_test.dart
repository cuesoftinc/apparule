import 'package:apparule/src/app/di.dart';
import 'package:apparule/src/features/feed/data/post_repository_fake.dart';
import 'package:apparule/src/features/feed/presentation/explore_view_model.dart';
import 'package:apparule/src/features/feed/presentation/home_feed_view_model.dart';
import 'package:apparule/src/features/profile/presentation/follow_list_view_model.dart';
import 'package:apparule/src/features/profile/presentation/notifications_view_model.dart';
import 'package:apparule/src/features/profile/presentation/profile_view_model.dart';
import 'package:apparule/src/features/profile/presentation/public_profile_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/in_memory_persistence.dart';

/// FollowGraphController two-surface contract (CLASS 1 + CLASS 2 locks):
/// the overlay flips SYNCHRONOUSLY (optimistic-by-construction), one
/// mutation re-derives EVERY declared surface — C12 lists, C9 headers,
/// C3 sections, C10's viewer set, and the C2 feed (D02) — and a failed
/// reconcile rolls the overlay back and rethrows.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const designer = 'tunde.o';

  late ProviderContainer container;
  late PostRepositoryFake repository;

  setUp(() async {
    repository = PostRepositoryFake(now: () => DateTime.utc(2026, 7, 22, 12));
    container = ProviderContainer(
      overrides: fakeRepositoryOverrides(
        persistenceService: InMemoryPersistenceService(),
        postRepository: repository,
      ),
    );
    addTearDown(container.dispose);

    // Keep-alive listeners on every declared fan-out surface.
    container
      ..listen(homeFeedViewModelProvider, (previous, next) {})
      ..listen(
        followListProvider(username: designer, kind: FollowListKind.followers),
        (previous, next) {},
      )
      ..listen(publicProfileViewModelProvider(designer), (previous, next) {})
      ..listen(profileViewModelProvider, (previous, next) {})
      ..listen(exploreViewModelProvider(query: designer), (previous, next) {})
      ..listen(viewerFollowingSetProvider, (previous, next) {});

    await container.read(homeFeedViewModelProvider.future);
    await container.read(
      followListProvider(
        username: designer,
        kind: FollowListKind.followers,
      ).future,
    );
    await container.read(publicProfileViewModelProvider(designer).future);
    await container.read(profileViewModelProvider.future);
    await container.read(exploreViewModelProvider(query: designer).future);
    await container.read(viewerFollowingSetProvider.future);
  });

  test('the overlay flips synchronously — the morph never waits for the '
      'round-trip (MI-18)', () async {
    final controller = container.read(followGraphControllerProvider.notifier);

    final pending = controller.setFollow(designer, follow: true);
    // BEFORE the repository answers: the local graph already says
    // following.
    expect(
      container.read(followGraphControllerProvider)[designer],
      isTrue,
    );
    await pending;
  });

  test('one follow re-derives every declared surface', () async {
    await container
        .read(followGraphControllerProvider.notifier)
        .setFollow(designer, follow: true);

    // D02: the mounted Home branch re-derives — tunde's posts join.
    final feed = await container.read(homeFeedViewModelProvider.future);
    expect(
      feed.posts.map((post) => post.designer.username).toSet(),
      contains(designer),
    );

    // C12: the designer's followers list gains the viewer.
    final followers = await container.read(
      followListProvider(
        username: designer,
        kind: FollowListKind.followers,
      ).future,
    );
    expect(followers.map((user) => user.username), contains('kiki.adeyemi'));

    // C9 public header morph + count.
    final publicProfile = await container.read(
      publicProfileViewModelProvider(designer).future,
    );
    expect(publicProfile.profile.viewerFollows, isTrue);

    // C9 own following count.
    final ownProfile = await container.read(profileViewModelProvider.future);
    expect(ownProfile?.followingCount, 3); // 2 seeded + tunde

    // C3 sections.
    final explore = await container.read(
      exploreViewModelProvider(query: designer).future,
    );
    expect(explore.designers.single.viewerFollows, isTrue);

    // C10 rows.
    final following = await container.read(viewerFollowingSetProvider.future);
    expect(following, contains(designer));
  });

  test('a failed reconcile rolls the overlay back and rethrows (the '
      'caller toasts via runAction)', () async {
    repository.failNext = Exception('server 500');
    final controller = container.read(followGraphControllerProvider.notifier);

    await expectLater(
      controller.setFollow(designer, follow: true),
      throwsException,
    );

    // Overlay reverted…
    expect(
      container.read(followGraphControllerProvider).containsKey(designer),
      isFalse,
    );
    // …and the repository never mutated.
    final feed = await container.read(homeFeedViewModelProvider.future);
    expect(
      feed.posts.map((post) => post.designer.username).toSet(),
      isNot(contains(designer)),
    );
  });
}
