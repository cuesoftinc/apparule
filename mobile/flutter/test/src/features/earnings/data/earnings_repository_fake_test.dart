import 'package:apparule/src/features/earnings/data/earnings_repository_fake.dart';
import 'package:apparule/src/features/earnings/domain/earnings.dart';
import 'package:apparule/src/features/earnings/domain/earnings_exception.dart';
import 'package:apparule/src/features/earnings/domain/payout.dart';
import 'package:flutter_test/flutter_test.dart';

/// The designer-monetization fake: the amara C14 canvas ledger, the
/// scripted Paystack resolution, the 9999999999 KYC-lapse fixture, and
/// HONEST payout-request mutation (balance moves, never resets).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  EarningsRepositoryFake fake({String viewer = 'kiki.adeyemi'}) =>
      EarningsRepositoryFake(
        viewer: viewer,
        now: () => DateTime.utc(2026, 7, 22, 12),
        resolveDelay: Duration.zero,
      );

  group('viewer perspectives over one narrative', () {
    test('the §6 test user has no designer side', () async {
      final status = await fake().status();

      expect(status.enabled, isFalse);
      expect(status.payoutAccount, isNull);
    });

    test('earnings for a non-designer throw designer_profile_required '
        '(web 403 parity)', () async {
      expect(
        fake().earnings,
        throwsA(
          isA<EarningsException>().having(
            (e) => e.code,
            'code',
            EarningsErrorCode.designerProfileRequired,
          ),
        ),
      );
    });

    test('amara carries the C14 canvas story: ₦82,500 available / '
        '₦45,000 escrow', () async {
      final repository = fake(viewer: 'amara.designs');
      final status = await repository.status();
      final earnings = await repository.earnings();

      expect(status.enabled, isTrue);
      expect(status.payoutAccount?.bankName, 'GTBank');
      expect(status.payoutAccount?.accountLast4, '4521');
      expect(status.payoutAccount?.accountName, 'AMARA OKAFOR');
      expect(status.payoutAccount?.kycState, KycState.verified);

      expect(earnings.availableCents, 8250000);
      // Pending derives from the escrow rows still held — #APR-1042
      // (the released #APR-1058 hold no longer counts).
      expect(earnings.pendingCents, 4500000);
      expect(earnings.transactions, hasLength(5));
      // Newest first: the Jul 16 payout leads the ledger.
      expect(earnings.transactions.first.id, 'txn-payout-1058');
      expect(earnings.transactions.first.amountCents, -5580000);
      expect(earnings.transactions.first.providerRef, 'PSK-9921404');
    });

    test('a designer without an earnings story reads empty, not an '
        'error', () async {
      final repository = fake(viewer: 'tunde.o');
      final earnings = await repository.earnings();

      expect(earnings.availableCents, 0);
      expect(earnings.pendingCents, 0);
      expect(earnings.transactions, isEmpty);
    });
  });

  group('C13 onboarding & the Paystack script (web store parity)', () {
    test(
      'enableDesigner opens the surface; earnings then read empty',
      () async {
        final repository = fake();
        final status = await repository.enableDesigner(
          username: 'kiki.adeyemi',
          displayName: 'Kiki Adeyemi',
          bio: 'aso-ebi sets & bridal',
        );

        expect(status.enabled, isTrue);
        expect((await repository.earnings()).transactions, isEmpty);
      },
    );

    test('enableDesigner validates the names', () async {
      expect(
        () => fake().enableDesigner(username: ' ', displayName: 'X'),
        throwsA(
          isA<EarningsException>().having(
            (e) => e.code,
            'code',
            EarningsErrorCode.validationFailed,
          ),
        ),
      );
    });

    test('a 10-digit number resolves to the holder name uppercased', () async {
      final repository = fake();
      await repository.enableDesigner(
        username: 'kiki.adeyemi',
        displayName: 'Kiki Adeyemi',
      );
      final resolution = await repository.resolveBank('058', '0123456789');

      expect(resolution.accountName, 'KIKI ADEYEMI');
    });

    test('a 00-prefixed number reproduces the failed state '
        'deterministically', () async {
      expect(
        () => fake().resolveBank('058', '0012345678'),
        throwsA(
          isA<EarningsException>().having(
            (e) => e.code,
            'code',
            EarningsErrorCode.bankResolutionFailed,
          ),
        ),
      );
    });

    test('an empty bank code is a validation failure', () async {
      expect(
        () => fake().resolveBank('', '0123456789'),
        throwsA(
          isA<EarningsException>().having(
            (e) => e.code,
            'code',
            EarningsErrorCode.validationFailed,
          ),
        ),
      );
    });

    test(
      'attachPayoutAccount verifies and stores the masked account',
      () async {
        final repository = fake();
        await repository.enableDesigner(
          username: 'kiki.adeyemi',
          displayName: 'Kiki Adeyemi',
        );
        final status = await repository.attachPayoutAccount(
          '058',
          '0123454521',
        );

        expect(status.payoutAccount?.kycState, KycState.verified);
        expect(status.payoutAccount?.bankName, 'GTBank');
        expect(status.payoutAccount?.accountLast4, '4521');
        expect(status.payoutAccount?.providerRef, 'PSTK-RCP-54521');
      },
    );

    test('9999999999 attaches then lapses — the KYC-banner fixture', () async {
      final repository = fake();
      await repository.enableDesigner(
        username: 'kiki.adeyemi',
        displayName: 'Kiki Adeyemi',
      );
      final status = await repository.attachPayoutAccount(
        '058',
        '9999999999',
      );

      expect(status.payoutAccount?.kycState, KycState.lapsed);

      // Re-verification with a good number recovers.
      final recovered = await repository.attachPayoutAccount(
        '044',
        '0123456789',
      );
      expect(recovered.payoutAccount?.kycState, KycState.verified);
      expect(recovered.payoutAccount?.bankName, 'Access Bank');
    });

    test('attaching without a designer profile throws', () async {
      expect(
        () => fake().attachPayoutAccount('058', '0123456789'),
        throwsA(
          isA<EarningsException>().having(
            (e) => e.code,
            'code',
            EarningsErrorCode.designerProfileRequired,
          ),
        ),
      );
    });
  });

  group('payout request mutates honestly', () {
    test('the released balance MOVES into a processing row', () async {
      final repository = fake(viewer: 'amara.designs');
      final before = await repository.earnings();
      final after = await repository.requestPayout();

      expect(after.availableCents, 0);
      // Pending grew by exactly the moved balance.
      expect(
        after.pendingCents,
        before.pendingCents + before.availableCents,
      );
      final requested = after.transactions.first;
      expect(requested.kind, EarningsEntryKind.payout);
      expect(requested.amountCents, -before.availableCents);
      expect(requested.label, 'Payout to GTBank ••• 4521');
      expect(requested.held, isTrue);
    });

    test('an empty balance cannot be paid out', () async {
      final repository = fake(viewer: 'tunde.o');
      expect(
        repository.requestPayout,
        throwsA(
          isA<EarningsException>().having(
            (e) => e.code,
            'code',
            EarningsErrorCode.validationFailed,
          ),
        ),
      );
    });
  });
}
