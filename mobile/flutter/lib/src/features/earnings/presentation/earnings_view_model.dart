import 'package:apparule/src/features/earnings/data/earnings_repository.dart';
import 'package:apparule/src/features/earnings/domain/earnings.dart';
import 'package:apparule/src/features/earnings/domain/payout.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'earnings_view_model.g.dart';

/// The viewer's designer/KYC state — the C9 settings rows, the C8
/// KYC-lapse banner, and C14's status line all watch this one
/// derivation.
@riverpod
Future<DesignerStatus> designerStatus(Ref ref) =>
    ref.watch(earningsRepositoryProvider).status();

/// C14's ViewModel — the summary + ledger. Non-designers surface as the
/// repository's `designer_profile_required` error, which the screen maps
/// to the become-a-designer empty state (web `EarningsView` parity).
@riverpod
class EarningsViewModel extends _$EarningsViewModel {
  @override
  Future<Earnings> build() => ref.watch(earningsRepositoryProvider).earnings();

  /// The ⋯ payout request — the fake moves the released balance into a
  /// processing row (honest mutation), and the summary re-renders from
  /// the returned ledger.
  Future<void> requestPayout() async {
    final updated = await ref.read(earningsRepositoryProvider).requestPayout();
    state = AsyncData(updated);
  }
}
