import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock.g.dart';

/// The UI clock — every screen-side "how long ago / how fresh" read goes
/// through this instead of a bare `DateTime.now()`, so golden scenarios
/// can pin one instant for BOTH the seeded fakes and the rendering pass
/// (relative labels and freshness ladders stay byte-stable).
@Riverpod(keepAlive: true)
DateTime Function() clock(Ref ref) => DateTime.now;
