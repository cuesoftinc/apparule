import 'package:apparule/src/core/ui/app_switch.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository_fake.dart';
import 'package:apparule/src/features/feed/data/media_picker_service.dart';
import 'package:apparule/src/features/feed/data/media_picker_service_fake.dart';
import 'package:apparule/src/features/feed/data/post_repository_fake.dart';
import 'package:apparule/src/features/feed/presentation/composer_screen.dart';
import 'package:apparule/src/features/feed/presentation/home_feed_screen.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository_fake.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/boot_app.dart';
import '../../../../helpers/button_state.dart';
import '../../../../helpers/notched.dart';

/// C15 — the designer post composer (canvas 551:2866 / 551:4152 / 552:2):
/// the empty state disarms Post and voices the media contract; adding
/// photos rides the `MediaPickerService` seam (bundled §6 samples);
/// publish walks the uploading state (per-tile strips + loading CTA +
/// null-locked inputs) through `runAction` — a failed publish toasts and
/// KEEPS the draft (CLASS 4), a successful one lands the author on the
/// feed the new post now leads.
void main() {
  const caption = 'Agbada set — brocade, relaxed fit.';

  Future<void> bootToComposer(
    WidgetTester tester, {
    MediaPickerServiceFake? mediaPicker,
    PostRepositoryFake? postRepository,
    MeasurementRepositoryFake? measurementRepository,
  }) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpBootedApp(
      tester,
      authRepository: AuthRepositoryFake(
        initialSession: AuthRepositoryFake.seedSession,
      ),
      // The designer perspective (the chooser's C15 gate) — the seeded
      // §6 viewer stays the post author.
      earningsRepository: EarningsRepositoryFake(
        viewer: 'amara.designs',
        resolveDelay: Duration.zero,
      ),
      mediaPickerService: mediaPicker,
      postRepository: postRepository,
      measurementRepository: measurementRepository,
    );
    routerOf(tester).go(const ComposerRoute().location);
    await tester.pumpAndSettle();
  }

  Future<void> addPhotosAndCaption(WidgetTester tester) async {
    await tester.tap(find.text('Add photos'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), caption);
    await tester.pump();
  }

  testWidgets('the empty composer disarms Post and voices the media '
      'contract (canvas 551:2866)', (tester) async {
    await bootToComposer(tester);

    expect(find.text('New post'), findsOneWidget);
    expect(find.text('Photos (0/10)'), findsOneWidget);
    expect(find.text('Add photos'), findsOneWidget);
    expect(
      find.text('Up to 10 photos — JPEG, PNG or WebP, 10 MB max.'),
      findsOneWidget,
    );
    expect(find.text('Caption'), findsOneWidget);
    expect(
      find.text('Attach measurement snapshot'),
      findsOneWidget,
    );
    // The differentiator toggle is ON by default.
    expect(tester.widget<AppSwitch>(find.byType(AppSwitch)).value, isTrue);
    expect(buttonEnabled(tester, 'Post'), isFalse);
  });

  testWidgets('photos alone do not arm Post — the caption is required; '
      'both together arm it', (tester) async {
    await bootToComposer(tester);

    await tester.tap(find.text('Add photos'));
    await tester.pumpAndSettle();

    // The fake picker serves the canvas ready-frame's 3 samples.
    expect(find.text('Photos (3/10)'), findsOneWidget);
    expect(buttonEnabled(tester, 'Post'), isFalse);

    await tester.enterText(find.byType(TextField), caption);
    await tester.pump();
    expect(buttonEnabled(tester, 'Post'), isTrue);

    // Caption cleared → Post disarms again (the gate re-evaluates).
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(buttonEnabled(tester, 'Post'), isFalse);
  });

  testWidgets('a remove dot drops its tile and the count follows', (
    tester,
  ) async {
    await bootToComposer(tester);
    await tester.tap(find.text('Add photos'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Remove photo 1'));
    await tester.pump();

    expect(find.text('Photos (2/10)'), findsOneWidget);
  });

  testWidgets('publish walks the uploading state — per-tile strips, '
      'loading CTA, null-locked inputs — then lands the post at the top '
      'of the feed', (tester) async {
    await bootToComposer(tester);
    await addPhotosAndCaption(tester);

    await tester.tap(find.text('Post'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Canvas 552:2 — every tile carries the strip, the CTA spins (the
    // loading Button swaps its label for the spinner, so assert the
    // widget's loading cell directly).
    expect(find.text('Uploading…'), findsNWidgets(3));
    expect(tester.widget<Button>(find.byType(Button)).loading, isTrue);
    // Null-handler locks: the remove dot ignores taps mid-flight…
    await tester.tap(find.bySemanticsLabel('Remove photo 1'));
    await tester.pump();
    expect(find.text('Photos (3/10)'), findsOneWidget);
    // …and the snapshot switch renders disabled.
    expect(
      tester.widget<AppSwitch>(find.byType(AppSwitch)).onChanged,
      isNull,
    );

    await tester.pumpAndSettle();

    // Success → the author lands on the feed the post now leads.
    expect(find.byType(HomeFeedScreen), findsOneWidget);
    expect(
      find.textContaining('Agbada set', findRichText: true),
      findsWidgets,
    );
  });

  testWidgets('a failed publish toasts and KEEPS the draft — media, '
      'caption and screen all survive (CLASS 4 failNext)', (tester) async {
    final postRepository = PostRepositoryFake(uploadDelay: Duration.zero);
    await bootToComposer(tester, postRepository: postRepository);
    await addPhotosAndCaption(tester);

    postRepository.failNext = Exception('server 500');
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong — try again.'), findsOneWidget);
    expect(find.byType(ComposerScreen), findsOneWidget);
    expect(find.text('Photos (3/10)'), findsOneWidget);
    expect(find.text(caption), findsOneWidget);
    // The seam disarmed — the retry is armed and would succeed.
    expect(postRepository.failNext, isNull);
    expect(buttonEnabled(tester, 'Post'), isTrue);
  });

  testWidgets('pick rejections voice the FIRST violation and keep the '
      'accepted set (type → size → count ordering)', (tester) async {
    final mediaPicker = MediaPickerServiceFake()
      ..enqueue(const <PickedMedia>[
        PickedMedia(
          url: '/demo/outfit-w16.jpg',
          sizeBytes: 11 * 1024 * 1024,
          mimeType: 'image/jpeg',
        ),
        PickedMedia(
          url: '/demo/outfit-w17.jpg',
          sizeBytes: 1024,
          mimeType: 'image/jpeg',
        ),
      ])
      ..enqueue(const <PickedMedia>[
        PickedMedia(
          url: '/demo/outfit-w18.jpg',
          sizeBytes: 1024,
          mimeType: 'image/heic',
        ),
      ]);
    await bootToComposer(tester, mediaPicker: mediaPicker);

    // Oversize + valid: the valid one lands, the size copy toasts.
    await tester.tap(find.text('Add photos'));
    await tester.pumpAndSettle();
    expect(find.text('Images must be 10 MB or smaller'), findsOneWidget);
    expect(find.text('Photos (1/10)'), findsOneWidget);

    // Wrong type: rejected with the web copy, count holds.
    await tester.tap(find.bySemanticsLabel('Add photos'));
    await tester.pumpAndSettle();
    expect(find.text('Images must be JPEG, PNG, or WebP'), findsOneWidget);
    expect(find.text('Photos (1/10)'), findsOneWidget);
  });

  testWidgets('an overflowing selection caps at 10, voices the count '
      'copy, and retires the add affordance', (tester) async {
    final mediaPicker = MediaPickerServiceFake()
      ..enqueue(<PickedMedia>[
        for (var i = 0; i < 11; i++)
          PickedMedia(
            url: MediaPickerServiceFake
                .samplePool[i % MediaPickerServiceFake.samplePool.length],
            sizeBytes: 1024,
            mimeType: 'image/jpeg',
          ),
      ]);
    await bootToComposer(tester, mediaPicker: mediaPicker);

    await tester.tap(find.text('Add photos'));
    await tester.pumpAndSettle();

    expect(find.text('Posts carry at most 10 images'), findsOneWidget);
    expect(find.text('Photos (10/10)'), findsOneWidget);
    expect(find.bySemanticsLabel('Add photos'), findsNothing);
  });

  testWidgets('the snapshot toggle ON stamps the vault-latest session '
      'ref; toggled OFF the post carries none', (tester) async {
    final postRepository = PostRepositoryFake(uploadDelay: Duration.zero);
    final measurementRepository = MeasurementRepositoryFake();
    await bootToComposer(
      tester,
      postRepository: postRepository,
      measurementRepository: measurementRepository,
    );
    final newestSessionId = await tester.runAsync(() async {
      final sessions = await measurementRepository.vaultSessions();
      return sessions.first.id;
    });

    await addPhotosAndCaption(tester);
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeFeedScreen), findsOneWidget);

    var feed = await tester.runAsync(() => postRepository.homeFeed());
    expect(feed!.first.snapshotSessionId, newestSessionId);
    // Required alt text defaulted per design.md §5.
    expect(feed.first.media.first.altText, 'Outfit by Kiki Adeyemi');

    // Second publish with the toggle OFF.
    routerOf(tester).push(const ComposerRoute().location);
    await tester.pumpAndSettle();
    await addPhotosAndCaption(tester);
    await tester.tap(find.byType(AppSwitch));
    await tester.pump();
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();

    feed = await tester.runAsync(() => postRepository.homeFeed());
    expect(feed!.first.snapshotSessionId, isNull);
  });

  testWidgets('keeps content clear of notch and status-bar top insets', (
    tester,
  ) async {
    applyNotchedView(tester);
    await pumpBootedApp(
      tester,
      authRepository: AuthRepositoryFake(
        initialSession: AuthRepositoryFake.seedSession,
      ),
      earningsRepository: EarningsRepositoryFake(
        viewer: 'amara.designs',
        resolveDelay: Duration.zero,
      ),
    );
    routerOf(tester).go(const ComposerRoute().location);
    await tester.pumpAndSettle();

    await expectContentClearOfTopInsets(tester);
  });
}
