import pytest

from kafka import topics
from kafka.consumer import Dispatcher
from payments.failed import failed_outcome
from tests.conftest import example


class Calls:
    def __init__(self, fail_times: int = 0):
        self.fail_times = fail_times
        self.handled: list[str | None] = []
        self.failures: list[tuple[str, str | None]] = []

    async def handler(self, msg: dict, request_id: str | None) -> None:
        self.handled.append(request_id)
        if len(self.handled) <= self.fail_times:
            raise ConnectionError("paystack away")

    async def on_failure(self, event: str, msg: dict, request_id: str | None) -> None:
        self.failures.append((event, request_id))


def dispatcher(contract, store, calls: Calls) -> Dispatcher:
    return Dispatcher({topics.ORDERS_TRANSITION: calls.handler}, contract, store, calls.on_failure, attempts=3, backoff=0)


async def test_a_handler_that_keeps_failing_is_answered_and_skipped(contract, store):
    calls = Calls(fail_times=100)
    message = example("orders.transition")
    await dispatcher(contract, store, calls).handle(topics.TOPIC_REQUESTS, message)  # never raises: the offset commits
    assert len(calls.handled) == 3
    assert calls.failures == [(topics.ORDERS_TRANSITION, message["request_id"])]


async def test_a_transient_failure_is_retried(contract, store):
    calls = Calls(fail_times=1)
    await dispatcher(contract, store, calls).handle(topics.TOPIC_REQUESTS, example("orders.transition"))
    assert len(calls.handled) == 2 and calls.failures == []


async def test_the_handler_gets_the_request_id(contract, store):
    calls = Calls()
    message = example("orders.transition")
    await dispatcher(contract, store, calls).handle(topics.TOPIC_REQUESTS, message)
    assert calls.handled == [message["request_id"]]


@pytest.mark.parametrize(
    "value",
    [
        {"type": "expendit.import.ready", "version": "1.0"},
        None,
    ],
)
async def test_other_products_messages_are_skipped(contract, store, value):
    calls = Calls()
    await dispatcher(contract, store, calls).handle(topics.TOPIC_REQUESTS, value)
    assert calls.handled == [] and calls.failures == []


async def test_an_unsupported_major_is_skipped_unhandled(contract, store):
    calls = Calls()
    await dispatcher(contract, store, calls).handle(topics.TOPIC_REQUESTS, example("orders.transition") | {"version": "2.0"})
    assert calls.handled == [] and calls.failures == []


def test_failed_outcomes_answer_money_requests(contract):
    delivered = example("orders.transition")["data"]
    out = failed_outcome(topics.ORDERS_TRANSITION, delivered)
    contract.validate_data(topics.PAYMENTS_OUTCOME, out)
    assert out["kind"] == "payout_failed" and out["reason"] == "processing_failed"

    charge = example("payments.provider_event")["data"]
    out = failed_outcome(topics.PROVIDER_EVENT, charge)
    contract.validate_data(topics.PAYMENTS_OUTCOME, out)
    assert out["kind"] == "charge_rejected" and out["request_id"] == charge["order"]["request_id"]

    recipient = example("payouts.recipient_requested")["data"]
    out = failed_outcome(topics.RECIPIENT_REQUESTED, recipient)
    contract.validate_data(topics.PAYMENTS_OUTCOME, out)
    assert out["kind"] == "recipient_failed"


def test_events_that_ask_for_no_money_decision_have_no_failed_outcome():
    assert failed_outcome(topics.NOTIFICATION_CREATED, example("notifications.created")["data"]) is None
    assert failed_outcome(topics.ORDERS_TRANSITION, example("orders.transition")["data"] | {"to": "shipped"}) is None
    assert failed_outcome(topics.RECONCILE_REQUESTED, example("ledger.reconcile_requested")["data"]) is None
