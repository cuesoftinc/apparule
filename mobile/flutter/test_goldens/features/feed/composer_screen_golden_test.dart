import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/features/feed/data/media_picker_service.dart';
import 'package:apparule/src/features/feed/presentation/composer_screen.dart';

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// C15 composer (canvas 551:2866 empty / 551:4152 ready / 552:2
/// uploading) — the three CTA states over the media grid, caption and
/// snapshot-attach toggle, both themes. The draft is screen-local, so
/// the ready/uploading cells pre-arrange it through the golden seams;
/// tiles render the bundled §6 demo pool (what the fake picker serves).
/// The uploading cell hosts the loading CTA's spinner, so the group
/// pumps bounded frames instead of settling.
void main() {
  const caption =
      'Agbada set — brocade, relaxed fit, made to your measurements.';
  const media = <PickedMedia>[
    PickedMedia(
      url: '/demo/outfit-w16.jpg',
      sizeBytes: 512 * 1024,
      mimeType: 'image/jpeg',
    ),
    PickedMedia(
      url: '/demo/outfit-w17.jpg',
      sizeBytes: 512 * 1024,
      mimeType: 'image/jpeg',
    ),
    PickedMedia(
      url: '/demo/outfit-w18.jpg',
      sizeBytes: 512 * 1024,
      mimeType: 'image/jpeg',
    ),
  ];

  themedGoldenTest(
    'ComposerScreen states',
    fileName: 'composer_screen',
    pumpBeforeTest: precacheThenFrame,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'empty — dashed add-zone, Post disabled',
          child: screenFrame(const ComposerScreen()),
        ),
        GoldenTestScenario(
          name: 'ready — 3 tiles + add-tile, caption, Post armed',
          child: screenFrame(
            const ComposerScreen(initialMedia: media, initialCaption: caption),
          ),
        ),
        GoldenTestScenario(
          name: 'uploading — per-tile strips, loading CTA, locked inputs',
          child: screenFrame(
            const ComposerScreen(
              initialMedia: media,
              initialCaption: caption,
              debugUploading: true,
            ),
          ),
        ),
      ],
    ),
  );
}
