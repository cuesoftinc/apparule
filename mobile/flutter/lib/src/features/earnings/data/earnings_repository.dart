import 'package:apparule/src/features/earnings/domain/payout.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'earnings_repository.g.dart';

/// Abstract earnings repository — C13/C14 (mobile-implementation.md §3).
abstract class EarningsRepository {
  /// The designer's payout history (C14).
  Future<List<Payout>> payouts();
}

/// Overridden per entrypoint (di.dart) — no default implementation exists
/// until the API wave lands `*Remote` (mobile-implementation.md §6).
@Riverpod(keepAlive: true)
EarningsRepository earningsRepository(Ref ref) => throw UnimplementedError(
  'earningsRepository must be overridden with a *Fake or *Remote '
  'implementation (mobile-implementation.md §6)',
);
