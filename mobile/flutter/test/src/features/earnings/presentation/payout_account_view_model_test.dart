import 'dart:async';

import 'package:apparule/src/features/earnings/data/earnings_repository.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository_fake.dart';
import 'package:apparule/src/features/earnings/domain/earnings_exception.dart';
import 'package:apparule/src/features/earnings/domain/payout.dart';
import 'package:apparule/src/features/earnings/presentation/payout_account_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

/// D03 (CLASS 8): the C13 Paystack-resolve state machine over
/// Completer-driven resolves — input during an in-flight resolve must
/// SUPERSEDE (restart or cleanly settle), never wedge `resolving`. The
/// audit's repro: edit mid-flight → the stale-result guard discarded the
/// completion and nothing restarted — spinner forever, no Save, no
/// Retry.
void main() {
  const gtb = BankOption(code: '058', name: 'GTBank');

  late _CompleterEarningsRepository repository;
  late ProviderContainer container;
  late PayoutAccountViewModel viewModel;

  PayoutFormState state() => container.read(payoutAccountViewModelProvider);

  setUp(() {
    repository = _CompleterEarningsRepository();
    container = ProviderContainer(
      overrides: <Override>[
        earningsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    // Keep-alive listener: without one, the autoDispose VM would be
    // torn down and re-created between reads (a fresh machine per
    // assertion proves nothing).
    final subscription = container.listen(
      payoutAccountViewModelProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    viewModel = container.read(payoutAccountViewModelProvider.notifier);
  });

  test('a complete pair starts a resolve; completion lands resolved', () async {
    viewModel
      ..setBank(gtb)
      ..setAccountNumber('0123456789');
    await pumpEventQueue();
    expect(state().phase, PayoutFormPhase.resolving);
    expect(repository.pending, hasLength(1));

    repository.completeNext(accountName: 'Kikelomo Adeyemi');
    await pumpEventQueue();
    expect(state().phase, PayoutFormPhase.resolved);
    expect(state().resolution?.accountName, 'Kikelomo Adeyemi');
  });

  test('editing mid-flight SUPERSEDES: the stale completion is dropped '
      'and the new resolve owns the state — never a wedge', () async {
    viewModel
      ..setBank(gtb)
      ..setAccountNumber('0123456789');
    await pumpEventQueue();
    expect(repository.pending, hasLength(1));

    // The user edits a digit while the first resolve is in flight —
    // a NEW resolve starts for the new number.
    viewModel.setAccountNumber('0123456780');
    await pumpEventQueue();
    expect(state().phase, PayoutFormPhase.resolving);
    expect(repository.pending, hasLength(2));

    // The STALE resolve completes: dropped — still resolving, owned by
    // the newer request (the audit's wedge was here: dropped with no
    // owner, spinner forever).
    repository.completeAt(0, accountName: 'Stale Name');
    await pumpEventQueue();
    expect(state().phase, PayoutFormPhase.resolving);
    expect(state().resolution, isNull);

    // The CURRENT resolve completes: the machine terminates.
    repository.completeAt(1, accountName: 'Kikelomo Adeyemi');
    await pumpEventQueue();
    expect(state().phase, PayoutFormPhase.resolved);
    expect(state().resolution?.accountName, 'Kikelomo Adeyemi');
  });

  test('shortening the number mid-flight settles idle and the in-flight '
      'completion cannot resurrect the spinner', () async {
    viewModel
      ..setBank(gtb)
      ..setAccountNumber('0123456789');
    await pumpEventQueue();
    expect(state().phase, PayoutFormPhase.resolving);

    // Delete a digit: incomplete pair → idle, in-flight invalidated.
    viewModel.setAccountNumber('012345678');
    await pumpEventQueue();
    expect(state().phase, PayoutFormPhase.idle);

    repository.completeAt(0, accountName: 'Ghost');
    await pumpEventQueue();
    expect(state().phase, PayoutFormPhase.idle);
    expect(state().resolution, isNull);
  });

  test('a failed CURRENT resolve lands failed and counts; a failed STALE '
      'resolve is dropped', () async {
    viewModel
      ..setBank(gtb)
      ..setAccountNumber('0123456789');
    await pumpEventQueue();

    viewModel.setAccountNumber('0123456780');
    await pumpEventQueue();

    // Stale failure: dropped, no failCount tick.
    repository.failAt(0);
    await pumpEventQueue();
    expect(state().phase, PayoutFormPhase.resolving);
    expect(state().failCount, 0);

    // Current failure: the failed state with retry in reach.
    repository.failAt(1);
    await pumpEventQueue();
    expect(state().phase, PayoutFormPhase.failed);
    expect(state().failCount, 1);

    // Retry starts a fresh resolve that can succeed.
    unawaited(viewModel.retry());
    await pumpEventQueue();
    expect(state().phase, PayoutFormPhase.resolving);
    repository.completeAt(2, accountName: 'Kikelomo Adeyemi');
    await pumpEventQueue();
    expect(state().phase, PayoutFormPhase.resolved);
  });
}

/// Completer-gated resolver over the seeded fake (the CLASS 8 recipe):
/// every `resolveBank` parks on its own Completer the test settles
/// explicitly, in any order — the only way to prove supersede semantics.
class _CompleterEarningsRepository extends EarningsRepositoryFake {
  final List<Completer<BankResolution>> pending = <Completer<BankResolution>>[];
  final List<(String, String)> requests = <(String, String)>[];

  @override
  Future<BankResolution> resolveBank(
    String bankCode,
    String accountNumber,
  ) {
    final completer = Completer<BankResolution>();
    pending.add(completer);
    requests.add((bankCode, accountNumber));
    return completer.future;
  }

  void completeAt(int index, {required String accountName}) {
    pending[index].complete(
      BankResolution(
        accountName: accountName,
        bankCode: requests[index].$1,
        accountNumber: requests[index].$2,
      ),
    );
  }

  void completeNext({required String accountName}) =>
      completeAt(pending.length - 1, accountName: accountName);

  void failAt(int index) {
    pending[index].completeError(
      const EarningsException(EarningsErrorCode.bankResolutionFailed),
    );
  }
}
