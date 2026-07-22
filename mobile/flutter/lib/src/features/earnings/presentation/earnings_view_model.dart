import 'package:apparule/src/features/earnings/data/earnings_repository.dart';
import 'package:apparule/src/features/earnings/domain/earnings.dart';
import 'package:apparule/src/features/earnings/domain/earnings_exception.dart';
import 'package:apparule/src/features/earnings/domain/payout.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'earnings_view_model.g.dart';

/// The viewer's designer/KYC state — the C9 settings rows, the C8
/// KYC-lapse banner, and C14's status line all watch this one
/// derivation.
@riverpod
Future<DesignerStatus> designerStatus(Ref ref) =>
    ref.watch(earningsRepositoryProvider).status();

/// C14's ViewModel — the summary + ledger. A null value is the
/// EXPECTED non-designer case (web 403 `designer_profile_required`),
/// mapped here rather than thrown: Riverpod 3 retries failing
/// providers, and "become a designer" is a state, not a failure.
@riverpod
class EarningsViewModel extends _$EarningsViewModel {
  @override
  Future<Earnings?> build() async {
    try {
      return await ref.watch(earningsRepositoryProvider).earnings();
    } on EarningsException catch (exception) {
      if (exception.code == EarningsErrorCode.designerProfileRequired) {
        return null;
      }
      rethrow;
    }
  }

  /// The ⋯ payout request — the fake moves the released balance into a
  /// processing row (honest mutation), and the summary re-renders from
  /// the returned ledger.
  Future<void> requestPayout() async {
    final updated = await ref.read(earningsRepositoryProvider).requestPayout();
    state = AsyncData(updated);
  }
}
