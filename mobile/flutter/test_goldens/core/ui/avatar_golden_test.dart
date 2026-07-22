import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/avatar.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_themes.dart';

/// Avatar (Figma 42:189) — `size` × `ring` × `badge`, both themes.
/// Initials fallback renders (image-free cells keep the goldens
/// deterministic; the photo path is covered by widget tests).
void main() {
  themedGoldenTest(
    'Avatar size × ring matrix',
    fileName: 'avatar',
    builder: () => GoldenTestGroup(
      columns: 4,
      children: <Widget>[
        for (final size in AvatarSize.values)
          for (final ring in AvatarRing.values)
            GoldenTestScenario(
              name: '${size.name} ring ${ring.name}',
              child: Avatar(
                name: 'Eniola Stitches',
                size: size,
                ring: ring,
              ),
            ),
      ],
    ),
  );

  themedGoldenTest(
    'Avatar designer-verified badge',
    fileName: 'avatar_badge',
    builder: () => GoldenTestGroup(
      columns: 5,
      children: <Widget>[
        for (final size in AvatarSize.values)
          GoldenTestScenario(
            name: '${size.name} designer-verified',
            child: Avatar(
              name: 'Eniola Stitches',
              size: size,
              badge: AvatarBadge.designerVerified,
            ),
          ),
      ],
    ),
  );
}
