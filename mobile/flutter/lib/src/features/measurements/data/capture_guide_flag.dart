import 'package:apparule/src/core/data/persistence_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'capture_guide_flag.g.dart';

/// Whether the C6 instructional guide has ever been completed
/// (mobile-implementation.md §10: guide first, "skippable after first
/// completion" — a persisted flag, not session state). The ➕ entry and
/// the vault's capture card branch on it; [markCompleted] flips it when
/// the guide's last page confirms.
@Riverpod(keepAlive: true)
class CaptureGuideFlag extends _$CaptureGuideFlag {
  @override
  Future<bool> build() =>
      ref.watch(persistenceServiceProvider).readCaptureGuideSeen();

  Future<void> markCompleted() async {
    await ref.read(persistenceServiceProvider).writeCaptureGuideSeen();
    state = const AsyncData<bool>(true);
  }
}
