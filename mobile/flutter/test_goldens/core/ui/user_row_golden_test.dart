import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/avatar.dart';
import 'package:apparule/src/core/ui/user_row.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_themes.dart';

/// UserRow (Figma §8.2b social rows) — trailing follow/following/none ×
/// avatar 32/44, both themes.
void main() {
  themedGoldenTest(
    'UserRow',
    fileName: 'user_row',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'trailing follow (gradient)',
          child: SizedBox(
            width: 390,
            child: UserRow(
              username: 'tunde.o',
              meta: 'Tunde Okonkwo · designer',
              verified: true,
              trailing: UserRowTrailing.follow,
              onFollow: () {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'trailing following (quiet)',
          child: SizedBox(
            width: 390,
            child: UserRow(
              username: 'amara.designs',
              meta: 'Amara Okafor · designer',
              verified: true,
              trailing: UserRowTrailing.following,
              onFollowingTap: () {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'none (regular account)',
          child: const SizedBox(
            width: 390,
            child: UserRow(username: 'ada.eze', meta: 'Ada Eze'),
          ),
        ),
        GoldenTestScenario(
          name: 'avatar 32 (dense sheet)',
          child: SizedBox(
            width: 390,
            child: UserRow(
              username: 'maisonbisi',
              meta: 'Maison Bisi · designer',
              avatarSize: AvatarSize.s32,
              trailing: UserRowTrailing.follow,
              onFollow: () {},
            ),
          ),
        ),
      ],
    ),
  );
}
