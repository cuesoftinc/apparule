import copy

import pytest

import payouts
import reconcile
from kafka import topics
from payments import outcome_id, platform_fee, settle
from payments.movements import Movements, payout_reference
from tests.conftest import FakePaystack, example, ok

FEE = 1000  # A-1: 10%


def test_fee_is_ten_percent_rounded_to_the_kobo():
    assert platform_fee(4_500_000, FEE) == 450_000
    assert platform_fee(1_005, FEE) == 101  # 100.5 rounds half up
    assert platform_fee(1_004, FEE) == 100


def _event(**changes) -> dict:
    msg = copy.deepcopy(example("payments.provider_event")["data"])
    msg["payload"].update(changes)
    return msg


def test_charge_that_matches_the_quote_settles(contract):
    out = settle.decide(_event(), FEE)
    contract.validate_data(topics.PAYMENTS_OUTCOME, out)
    assert out["kind"] == "charge_settled"
    assert out["fee"]["amount"] == 450_000
    assert sum(line["amount"] for line in out["ledger"]) == 0
    # Deterministic: the same event decides the same outcome id.
    assert settle.decide(_event(), FEE)["outcome_id"] == out["outcome_id"]


@pytest.mark.parametrize("change,reason", [
    ({"amount": 4_400_000}, "amount_mismatch"),
    ({"currency": "USD"}, "currency_mismatch"),
])
def test_charge_that_disagrees_is_rejected(contract, change, reason):
    out = settle.decide(_event(**change), FEE)
    contract.validate_data(topics.PAYMENTS_OUTCOME, out)
    assert out["kind"] == "charge_rejected" and out["reason"] == reason


def test_charge_for_an_order_no_longer_quoted_or_unknown(contract):
    msg = _event()
    msg["order"]["status"] = "cancelled"
    assert settle.decide(msg, FEE)["reason"] == "order_not_payable"
    msg["order"] = None
    out = settle.decide(msg, FEE)
    contract.validate_data(topics.PAYMENTS_OUTCOME, out)
    assert out["reason"] == "unknown_reference"


def test_informational_events_need_no_decision():
    msg = _event()
    msg["event"] = "transfer.success"
    assert settle.decide(msg, FEE) is None


def _delivered() -> dict:
    return copy.deepcopy(example("orders.transition")["data"])


async def test_delivery_releases_quote_minus_fee(contract):
    fake = FakePaystack({("POST", "/transfer"): ok({"transfer_code": "TRF_1", "status": "pending"})})
    out = await Movements(fake.client(), FEE).on_transition(_delivered())
    contract.validate_data(topics.PAYMENTS_OUTCOME, out)
    assert out["kind"] == "payout_released"
    assert out["amount"]["amount"] == 4_050_000 and out["fee"]["amount"] == 450_000
    assert sum(line["amount"] for line in out["ledger"]) == 0
    method, path, body = fake.calls[0]
    assert body["amount"] == 4_050_000 and body["reference"] == payout_reference(_delivered()["request_id"])


async def test_a_repeated_payout_is_not_paid_twice(contract):
    fake = FakePaystack({("POST", "/transfer"): (400, {"status": False, "message": "Duplicate Transfer Reference"})})
    out = await Movements(fake.client(), FEE).on_transition(_delivered())
    assert out["kind"] == "payout_released"


async def test_payout_without_a_recipient_or_with_paystack_down_fails_for_a_human(contract):
    msg = _delivered()
    del msg["payout_recipient"]
    out = await Movements(FakePaystack({}).client(), FEE).on_transition(msg)
    contract.validate_data(topics.PAYMENTS_OUTCOME, out)
    assert out == {**out, "kind": "payout_failed", "reason": "no_recipient"}
    down = FakePaystack({("POST", "/transfer"): (503, {})})
    out = await Movements(down.client(), FEE).on_transition(_delivered())
    assert out["kind"] == "payout_failed" and out["reason"] == "provider_error" and len(down.calls) == 3


async def test_refund_returns_the_whole_charge(contract):
    msg = _delivered() | {"to": "refunded", "from": "paid"}
    fake = FakePaystack({("POST", "/refund"): ok({"id": 991})})
    out = await Movements(fake.client(), FEE).on_transition(msg)
    contract.validate_data(topics.PAYMENTS_OUTCOME, out)
    assert out["kind"] == "refund_issued" and out["amount"]["amount"] == 4_500_000
    assert fake.calls[0][2] == {"transaction": "4099260516", "amount": 4_500_000}


async def test_other_transitions_move_no_money():
    msg = _delivered() | {"to": "shipped", "from": "in_progress"}
    assert await Movements(FakePaystack({}).client(), FEE).on_transition(msg) is None


@pytest.mark.parametrize("resolved,holder,ok_", [
    ("OKAFOR ADAEZE CHIOMA", "Adaeze Okafor", True),
    ("ADAEZE OKAFOR", "Adaeze", True),
    ("JOHN DOE", "Adaeze Okafor", False),
    ("ADAEZE NWOSU", "Adaeze Okafor", False),
])
def test_names_match(resolved, holder, ok_):
    assert payouts.names_match(resolved, holder) is ok_


async def test_recipient_is_verified(contract):
    msg = example("payouts.recipient_requested")["data"]
    fake = FakePaystack({("GET", "/bank/resolve"): ok({"account_name": "OKAFOR ADAEZE"}),
                         ("POST", "/transferrecipient"): ok({"recipient_code": "RCP_x"})})
    out = await payouts.verify(fake.client(), msg)
    contract.validate_data(topics.PAYMENTS_OUTCOME, out)
    assert out["kind"] == "recipient_verified"
    assert out["recipient"] == {"recipient_code": "RCP_x", "account_name": "OKAFOR ADAEZE", "bank_name": "GTBank", "last4": "6789"}


async def test_recipient_fails_on_a_name_mismatch_or_bad_account(contract):
    msg = example("payouts.recipient_requested")["data"]
    mismatch = FakePaystack({("GET", "/bank/resolve"): ok({"account_name": "JOHN DOE"})})
    out = await payouts.verify(mismatch.client(), msg)
    contract.validate_data(topics.PAYMENTS_OUTCOME, out)
    assert out["reason"] == "name_mismatch" and len(mismatch.calls) == 1
    invalid = FakePaystack({("GET", "/bank/resolve"): (422, {"status": False, "message": "Could not resolve account name"})})
    assert (await payouts.verify(invalid.client(), msg))["reason"] == "account_invalid"


async def test_reconcile_flags_every_disagreement(contract):
    msg = example("ledger.reconcile_requested")["data"]
    msg["movements"] = [
        {"request_id": msg["movements"][0]["request_id"], "kind": "charge", "reference": "4099260516",
         "amount": {"amount": 4_500_000, "currency": "NGN"}},
        {"request_id": msg["movements"][0]["request_id"], "kind": "payout", "reference": "TRF_gone",
         "amount": {"amount": 4_050_000, "currency": "NGN"}},
    ]
    fake = FakePaystack({
        ("GET", "/transaction"): ok([{"id": 4099260516, "reference": "apr_x", "amount": 4_400_000, "currency": "NGN"},
                                     {"id": 5550001, "reference": "apr_y", "amount": 1000, "currency": "NGN"}]),
        ("GET", "/transfer"): ok([]),
        ("GET", "/refund"): ok([]),
    })
    out = await reconcile.compare(fake.client(), msg)
    for o in out:
        contract.validate_data(topics.PAYMENTS_OUTCOME, o)
    assert sorted(o["reason"] for o in out) == ["amount_mismatch", "missing_in_ledger", "missing_in_provider"]


def test_outcome_ids_differ_by_kind_and_source():
    assert outcome_id("charge_settled", "a") != outcome_id("charge_rejected", "a")
    assert outcome_id("charge_settled", "a") == outcome_id("charge_settled", "a")
