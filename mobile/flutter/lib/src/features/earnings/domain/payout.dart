import 'package:freezed_annotation/freezed_annotation.dart';

part 'payout.freezed.dart';

/// Paystack KYC state on the payout account (pages.md B8/C13; web
/// `payout_account.kyc_state`). `lapsed` drives the persistent warn
/// banner: posts stop accepting requests, payouts queue until
/// re-verification.
enum KycState { pending, verified, lapsed }

/// The attached payout account (C13 verified state / the C14 status
/// line) — web `DesignerProfile.payout_account` parity.
@freezed
abstract class PayoutAccount with _$PayoutAccount {
  const factory PayoutAccount({
    required String providerRef,
    required String bankCode,
    required String bankName,
    required String accountLast4,
    required String accountName,
    required KycState kycState,
  }) = _PayoutAccount;
}

/// The designer-monetization state the C13/C14 surfaces read: whether a
/// designer profile exists and what payout account backs it. The account
/// domain (profile feature) deliberately doesn't carry this —
/// repositories never reference each other (mobile-implementation.md §3).
@freezed
abstract class DesignerStatus with _$DesignerStatus {
  const factory DesignerStatus({
    @Default(false) bool enabled,
    String? username,
    String? displayName,
    String? bio,
    PayoutAccount? payoutAccount,
  }) = _DesignerStatus;
}

/// A resolved bank account — the Paystack name-resolution result the
/// C13 form confirms against the profile (web `BankResolution`).
@freezed
abstract class BankResolution with _$BankResolution {
  const factory BankResolution({
    required String accountName,
    required String bankCode,
    required String accountNumber,
  }) = _BankResolution;
}

/// One NG bank the C13 Select offers (web store `BANK_NAMES` parity).
@freezed
abstract class BankOption with _$BankOption {
  const factory BankOption({
    required String code,
    required String name,
  }) = _BankOption;
}
