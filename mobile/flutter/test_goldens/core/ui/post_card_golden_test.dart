import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/post_card.dart';
import 'package:flutter/material.dart';
import '../../helpers/golden_themes.dart';
import '../../helpers/test_images.dart';

/// PostCard (Figma 52:462) — `media` single/carousel · `cta` true/false ·
/// `state` default/skeleton, both themes. Media rides the deterministic
/// 1×1 stand-in; the skeleton cell shimmers, so both suites pump a fixed
/// frame after precaching.
void main() {
  themedGoldenTest(
    'PostCard matrix',
    fileName: 'post_card',
    pumpBeforeTest: precacheThenFrame,
    builder: () => GoldenTestGroup(
      columns: 2,
      children: <Widget>[
        GoldenTestScenario(
          name: 'media single · cta false',
          child: SizedBox(
            width: 390,
            child: PostCard(
              username: 'eniola.stitches',
              verified: true,
              media: <ImageProvider<Object>>[grayPixelImage],
              liked: false,
              saved: false,
              likeCount: 1204,
              commentCount: 18,
              caption: 'Ankara two-piece, ready in 10 days.',
              timestampLabel: '2h',
              onToggleLike: () {},
              onToggleSave: () {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'media carousel · cta true · liked+saved',
          child: SizedBox(
            width: 390,
            child: PostCard(
              username: 'eniola.stitches',
              verified: true,
              media: <ImageProvider<Object>>[
                grayPixelImage,
                grayPixelImage,
                grayPixelImage,
              ],
              liked: true,
              saved: true,
              likeCount: 1204,
              commentCount: 18,
              caption:
                  'Ankara two-piece, ready in 10 days. Fully lined bodice '
                  'with a structured peplum and matching headwrap included.',
              timestampLabel: '2h',
              onToggleLike: () {},
              onToggleSave: () {},
              onRequest: () {},
            ),
          ),
        ),
      ],
    ),
  );

  themedGoldenTest(
    'PostCard skeleton',
    fileName: 'post_card_skeleton',
    pumpBeforeTest: pumpFrame,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <Widget>[
        GoldenTestScenario(
          name: 'state skeleton (MI-19)',
          child: const SizedBox(
            width: 390,
            child: PostCard(
              username: '',
              media: <ImageProvider<Object>>[],
              liked: false,
              saved: false,
              likeCount: 0,
              caption: '',
              skeleton: true,
            ),
          ),
        ),
      ],
    ),
  );
}
