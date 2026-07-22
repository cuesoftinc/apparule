import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/utils/clock.dart';
import 'package:apparule/src/features/profile/data/notification_repository_fake.dart';
import 'package:apparule/src/features/profile/presentation/notifications_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// C10 — day-grouped activity with unread tints/dots and the caught-up
/// divider, both themes.
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  themedGoldenTest(
    'NotificationsScreen seeded',
    fileName: 'notifications_screen',
    pumpBeforeTest: settleThenPrecache,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'grouped, part unread',
          child: screenFrame(
            const NotificationsScreen(),
            notificationRepository: NotificationRepositoryFake(
              now: () => pinned,
            ),
            overrides: <Override>[
              clockProvider.overrideWith(
                (ref) =>
                    () => pinned,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
