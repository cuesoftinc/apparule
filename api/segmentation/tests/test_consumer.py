from kafka import topics
from kafka.consumer import Dispatcher
from tests.conftest import example


class Calls:
    def __init__(self, fail_times: int = 0):
        self.fail_times = fail_times
        self.handled: list[str | None] = []
        self.failures: list[tuple[str, dict, str | None]] = []

    async def handler(self, msg: dict, request_id: str | None) -> None:
        self.handled.append(request_id)
        if len(self.handled) <= self.fail_times:
            raise RuntimeError("model crashed")

    async def on_failure(self, event: str, msg: dict, request_id: str | None) -> None:
        self.failures.append((event, msg, request_id))


def dispatcher(contract, store, calls: Calls) -> Dispatcher:
    return Dispatcher({topics.CAPTURE_READY: calls.handler}, contract, store, calls.on_failure, attempts=3, backoff=0)


async def test_a_capture_that_keeps_failing_is_answered_and_skipped(contract, store):
    calls = Calls(fail_times=100)
    message = example("capture.ready")
    await dispatcher(contract, store, calls).handle(topics.TOPIC_REQUESTS, message)  # never raises: the offset commits
    assert calls.handled == [message["request_id"]] * 3
    [(event, msg, request_id)] = calls.failures
    assert event == topics.CAPTURE_READY and msg["session_id"] == message["data"]["session_id"]
    assert request_id == message["request_id"]


async def test_a_transient_failure_is_retried(contract, store):
    calls = Calls(fail_times=2)
    await dispatcher(contract, store, calls).handle(topics.TOPIC_REQUESTS, example("capture.ready"))
    assert len(calls.handled) == 3 and calls.failures == []


async def test_a_bad_message_is_dropped_unhandled(contract, store):
    calls = Calls()
    broken = example("capture.ready")
    del broken["data"]["poses"]
    await dispatcher(contract, store, calls).handle(topics.TOPIC_REQUESTS, broken)
    await dispatcher(contract, store, calls).handle(topics.TOPIC_REQUESTS, example("capture.ready") | {"version": "2.0"})
    await dispatcher(contract, store, calls).handle(topics.TOPIC_REQUESTS, {"type": "expendit.import.ready"})
    assert calls.handled == [] and calls.failures == []
