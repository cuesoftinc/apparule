import 'package:apparule/src/core/data/seed_json.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository.dart';
import 'package:apparule/src/features/earnings/domain/earnings.dart';
import 'package:apparule/src/features/earnings/domain/earnings_exception.dart';
import 'package:apparule/src/features/earnings/domain/payout.dart';
import 'package:flutter/services.dart';

/// Seed-backed fake (mobile-implementation.md §6): the designer-
/// monetization story over `earnings.json` — `amara.designs` carries the
/// ratified C14 canvas ledger (₦82,500 available / ₦45,000 escrow) — with
/// the web store's SEMANTICS as real mutations: `enableDesigner` opens
/// the designer surface, the Paystack resolution script fails
/// deterministically (`00…` prefix), `9999999999` attaches then lapses
/// (the KYC-lapse banner fixture), and a payout request MOVES the
/// released balance into a processing row (pending) instead of
/// cosmetically resetting it. State lives for the provider's keepAlive
/// lifetime.
class EarningsRepositoryFake implements EarningsRepository {
  /// [viewer] switches the seeded perspective over the same narrative:
  /// the default §6 test user (`kiki.adeyemi`) is a non-designer — dev
  /// walks C13 to open the surface; tests/goldens pass `amara.designs`
  /// to render the populated C14 story. [resolveDelay] paces the C13
  /// "Checking with your bank…" state (zero in tests).
  EarningsRepositoryFake({
    AssetBundle? bundle,
    DateTime Function()? now,
    this.viewer = 'kiki.adeyemi',
    this.resolveDelay = const Duration(milliseconds: 1200),
  }) : _bundle = bundle ?? PlatformAssetBundle(),
       _now = now ?? DateTime.now;

  static const String _meAsset = 'assets/seed/dev/me.json';
  static const String _designersAsset = 'assets/seed/dev/designers.json';
  static const String _earningsAsset = 'assets/seed/dev/earnings.json';

  /// Web store `BANK_NAMES` parity.
  static const List<BankOption> bankOptions = <BankOption>[
    BankOption(code: '058', name: 'GTBank'),
    BankOption(code: '044', name: 'Access Bank'),
    BankOption(code: '057', name: 'Zenith Bank'),
    BankOption(code: '011', name: 'First Bank'),
    BankOption(code: '033', name: 'UBA'),
  ];

  final AssetBundle _bundle;
  final DateTime Function() _now;
  final String viewer;
  final Duration resolveDelay;

  bool _loaded = false;
  DesignerStatus _status = const DesignerStatus();
  String _viewerDisplayName = '';
  int _availableCents = 0;
  String _currency = 'NGN';
  final List<EarningsEntry> _transactions = <EarningsEntry>[];
  int _payoutSequence = 0;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final now = _now();

    if (await loadSeedJson(_bundle, _meAsset) case final me?) {
      if (me['username'] == viewer) {
        _viewerDisplayName = me['display_name'] as String? ?? viewer;
      }
    }
    if (await loadSeedJson(_bundle, _designersAsset) case final seed?) {
      for (final entry in seed['designers'] as List<dynamic>) {
        final json = entry as Map<String, dynamic>;
        if (json['username'] == viewer) {
          _viewerDisplayName = json['display_name'] as String;
          _status = DesignerStatus(
            enabled: true,
            username: viewer,
            displayName: json['display_name'] as String,
            bio: json['bio'] as String?,
          );
        }
      }
    }
    if (await loadSeedJson(_bundle, _earningsAsset) case final seed?) {
      final designers = seed['designers'] as Map<String, dynamic>;
      if (designers[viewer] case final Map<String, dynamic> story) {
        if (story['payout_account'] case final Map<String, dynamic> account) {
          _status = _status.copyWith(
            payoutAccount: PayoutAccount(
              providerRef: account['provider_ref'] as String,
              bankCode: account['bank_code'] as String,
              bankName: account['bank_name'] as String,
              accountLast4: account['account_last4'] as String,
              accountName: account['account_name'] as String,
              kycState: KycState.values.byName(
                account['kyc_state'] as String,
              ),
            ),
          );
        }
        _availableCents = (story['available_cents'] as num).toInt();
        _currency = story['currency'] as String? ?? 'NGN';
        for (final entry in story['transactions'] as List<dynamic>) {
          final json = entry as Map<String, dynamic>;
          _transactions.add(
            EarningsEntry(
              id: json['id'] as String,
              kind: switch (json['kind'] as String) {
                'payout' => EarningsEntryKind.payout,
                'escrow_held' => EarningsEntryKind.escrowHeld,
                'fee_line' => EarningsEntryKind.feeLine,
                final kind => throw StateError('Unknown entry kind: $kind'),
              },
              amountCents: (json['amount_cents'] as num).toInt(),
              currency: json['currency'] as String? ?? 'NGN',
              label: json['label'] as String?,
              orderNumber: json['order_number'] as String?,
              providerRef: json['provider_ref'] as String?,
              createdAt: seedDaysAgo(now, json['created_days_ago'] as num),
              held: json['state'] == 'held',
            ),
          );
        }
      }
    }
  }

  int get _pendingCents => _transactions
      .where((entry) => entry.held)
      .fold(0, (sum, entry) => sum + entry.amountCents.abs());

  Earnings _earningsView() => Earnings(
    availableCents: _availableCents,
    pendingCents: _pendingCents,
    currency: _currency,
    transactions: _transactions.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
  );

  @override
  Future<DesignerStatus> status() async {
    await _ensureLoaded();
    return _status;
  }

  @override
  Future<DesignerStatus> enableDesigner({
    required String username,
    required String displayName,
    String? bio,
  }) async {
    await _ensureLoaded();
    if (username.trim().isEmpty || displayName.trim().isEmpty) {
      throw const EarningsException(
        EarningsErrorCode.validationFailed,
        'Username and display name are required',
      );
    }
    _viewerDisplayName = displayName.trim();
    return _status = _status.copyWith(
      enabled: true,
      username: username.trim(),
      displayName: displayName.trim(),
      bio: bio?.trim(),
    );
  }

  @override
  Future<List<BankOption>> banks() async => bankOptions;

  @override
  Future<BankResolution> resolveBank(
    String bankCode,
    String accountNumber,
  ) async {
    await _ensureLoaded();
    await Future<void>.delayed(resolveDelay);
    if (bankCode.isEmpty) {
      throw const EarningsException(
        EarningsErrorCode.validationFailed,
        'Pick your bank',
      );
    }
    // Web store parity: 10 digits resolve; a `00` prefix reproduces the
    // mismatch/unresolvable path deterministically.
    if (!RegExp(r'^\d{10}$').hasMatch(accountNumber) ||
        accountNumber.startsWith('00')) {
      throw const EarningsException(
        EarningsErrorCode.bankResolutionFailed,
        'Could not resolve that account number',
      );
    }
    return BankResolution(
      accountName: _viewerDisplayName.toUpperCase(),
      bankCode: bankCode,
      accountNumber: accountNumber,
    );
  }

  @override
  Future<DesignerStatus> attachPayoutAccount(
    String bankCode,
    String accountNumber,
  ) async {
    await _ensureLoaded();
    if (!_status.enabled) {
      throw const EarningsException(
        EarningsErrorCode.designerProfileRequired,
        'Enable a designer profile first',
      );
    }
    final resolution = await resolveBank(bankCode, accountNumber);
    // Designated fixture: 9999999999 attaches, then the provider
    // invalidates it — the KYC-lapse banner state (flows/designer.md §1).
    final lapsed = accountNumber == '9999999999';
    return _status = _status.copyWith(
      payoutAccount: PayoutAccount(
        providerRef: 'PSTK-RCP-${accountNumber.substring(5)}',
        bankCode: bankCode,
        bankName: bankOptions
            .firstWhere(
              (bank) => bank.code == bankCode,
              orElse: () => BankOption(code: bankCode, name: bankCode),
            )
            .name,
        accountLast4: accountNumber.substring(6),
        accountName: resolution.accountName,
        kycState: lapsed ? KycState.lapsed : KycState.verified,
      ),
    );
  }

  @override
  Future<Earnings> earnings() async {
    await _ensureLoaded();
    if (!_status.enabled) {
      throw const EarningsException(
        EarningsErrorCode.designerProfileRequired,
        'Earnings are available to designer profiles only',
      );
    }
    return _earningsView();
  }

  @override
  Future<Earnings> requestPayout() async {
    await _ensureLoaded();
    if (!_status.enabled) {
      throw const EarningsException(
        EarningsErrorCode.designerProfileRequired,
        'Earnings are available to designer profiles only',
      );
    }
    if (_availableCents <= 0) {
      throw const EarningsException(
        EarningsErrorCode.validationFailed,
        'Nothing to pay out',
      );
    }
    final account = _status.payoutAccount;
    // Honest mutation: the released balance MOVES into a processing
    // payout row — pending until the provider settles it, exactly the
    // story the summary cards retell.
    _transactions.add(
      EarningsEntry(
        id: 'txn-payout-local-${++_payoutSequence}',
        kind: EarningsEntryKind.payout,
        amountCents: -_availableCents,
        currency: _currency,
        label: account == null
            ? 'Payout requested'
            : 'Payout to ${account.bankName} ••• ${account.accountLast4}',
        createdAt: _now(),
        held: true,
      ),
    );
    _availableCents = 0;
    return _earningsView();
  }
}
