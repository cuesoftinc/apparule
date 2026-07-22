import 'package:apparule/src/core/data/persistence_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'first_save_flag.g.dart';

/// Whether the MI-3 first-save toast has ever shown (design.md §4:
/// "first-ever save shows 'Saved to your looks' toast with link" — once
/// per install, mirroring web's `first-save.ts` localStorage gate).
/// Saved state itself lives in the post repository; this only gates the
/// one-time toast.
@Riverpod(keepAlive: true)
class FirstSaveFlag extends _$FirstSaveFlag {
  @override
  Future<bool> build() =>
      ref.watch(persistenceServiceProvider).readFirstSaveToastShown();

  /// Marks the toast shown; resolves true when THIS call claimed the
  /// first save (callers show the toast only then).
  Future<bool> claim() async {
    // Settle the initial read first — assigning state while build() is
    // in flight would be clobbered when the read resolves.
    final shown = await future;
    if (shown) return false;
    state = const AsyncData<bool>(true);
    await ref.read(persistenceServiceProvider).writeFirstSaveToastShown();
    return true;
  }
}
