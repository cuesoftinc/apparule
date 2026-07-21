import 'package:apparule/src/features/earnings/data/earnings_repository.dart';
import 'package:apparule/src/features/earnings/domain/payout.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'earnings_view_model.g.dart';

/// C14 placeholder ViewModel — watches the abstract earnings
/// repository; dev/stg overrides supply the fake.
@riverpod
class EarningsViewModel extends _$EarningsViewModel {
  @override
  Future<List<Payout>> build() =>
      ref.watch(earningsRepositoryProvider).payouts();
}
