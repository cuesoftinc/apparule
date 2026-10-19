import json

import pytest

from kafka import envelope, topics
from tests.conftest import CONTRACT_DIR, example

EXAMPLES = sorted(p.stem for p in (CONTRACT_DIR / "examples").glob("*.json"))


@pytest.mark.parametrize("name", EXAMPLES)
def test_examples_match_schemas(contract, name):
    message = example(name)
    contract.validate_envelope(message)
    contract.validate_data(message["type"], message["data"])


async def test_outcomes_go_by_reference(contract, store):
    data = example("payments.outcome")["data"]
    message = await envelope.wrap(topics.PAYMENTS_OUTCOME, data, contract, store, "apparule/test")
    assert "data" not in message and "4500000" not in json.dumps(message)
    assert await envelope.unwrap(topics.TOPIC_RESULTS, message, contract, store) == (topics.PAYMENTS_OUTCOME, data)


def test_every_handled_event_rides_a_shared_lane():
    assert set(topics.TOPIC_FOR.values()) <= {topics.TOPIC_UPLOADS, topics.TOPIC_REQUESTS, topics.TOPIC_RESULTS}
    assert all(event.startswith("apparule.") for event in topics.TOPIC_FOR)
