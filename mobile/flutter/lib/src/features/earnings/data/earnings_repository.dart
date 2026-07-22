import 'package:apparule/src/features/earnings/domain/earnings.dart';
import 'package:apparule/src/features/earnings/domain/payout.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'earnings_repository.g.dart';

/// Abstract designer-monetization repository — C13 onboarding/KYC + C14
/// earnings & payouts, one repository for the designer-monetization
/// surface (mobile-implementation.md §3: matches web's B8/B9 pairing).
abstract class EarningsRepository {
  /// The viewer's designer/KYC state — the C9 gear rows, the C8
  /// KYC-lapse banner, and the C14 status line all read this.
  Future<DesignerStatus> status();

  /// C13 intro: create the designer profile (posts right away; banking
  /// details attach when ready to accept requests). Throws
  /// `validation_failed` on empty names (web `enableDesigner` parity).
  Future<DesignerStatus> enableDesigner({
    required String username,
    required String displayName,
    String? bio,
  });

  /// The C13 bank Select options (web store `BANK_NAMES` parity).
  Future<List<BankOption>> banks();

  /// Paystack account resolution (pages.md B8 scripted states): a
  /// 10-digit number resolves to the holder's registered name; numbers
  /// starting `00` reproduce the mismatch/unresolvable path
  /// deterministically (`bank_resolution_failed`).
  Future<BankResolution> resolveBank(String bankCode, String accountNumber);

  /// Attach the resolved account. The designated fixture `9999999999`
  /// attaches and then lapses — reproducing the KYC-lapse banner state
  /// (flows/designer.md §1).
  Future<DesignerStatus> attachPayoutAccount(
    String bankCode,
    String accountNumber,
  );

  /// The C14 summary + ledger. Throws `designer_profile_required` for
  /// non-designers (web 403 parity — C14 renders the become-a-designer
  /// empty state).
  Future<Earnings> earnings();

  /// Requests an early payout of the released balance: the fake mutates
  /// honestly — available moves into a processing payout row, never a
  /// cosmetic reset.
  Future<Earnings> requestPayout();
}

/// Overridden per entrypoint (di.dart) — no default implementation exists
/// until the API wave lands `*Remote` (mobile-implementation.md §6).
@Riverpod(keepAlive: true)
EarningsRepository earningsRepository(Ref ref) => throw UnimplementedError(
  'earningsRepository must be overridden with a *Fake or *Remote '
  'implementation (mobile-implementation.md §6)',
);
