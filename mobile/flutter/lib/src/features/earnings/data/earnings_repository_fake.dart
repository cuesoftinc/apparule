import 'package:apparule/src/features/earnings/data/earnings_repository.dart';
import 'package:apparule/src/features/earnings/domain/payout.dart';

/// Empty-state fake — the seeded §6 narrative (assets/seed/) arrives with
/// the screens wave; the interface seam is what this wave establishes.
class EarningsRepositoryFake implements EarningsRepository {
  @override
  Future<List<Payout>> payouts() async => const <Payout>[];
}
