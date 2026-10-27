import json

import pytest

from contract import ContractError
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
    message = await envelope.wrap(topics.PAYMENTS_OUTCOME, data, contract, store, "apparule/test", "req-1")
    assert "data" not in message and "4500000" not in json.dumps(message)
    assert message["version"] == "1.0" and message["request_id"] == "req-1"
    assert await envelope.unwrap(topics.TOPIC_RESULTS, message, contract, store) == (topics.PAYMENTS_OUTCOME, data, "req-1")


async def test_a_request_hands_over_its_request_id(contract, store):
    message = example("orders.transition")
    _, _, request_id = await envelope.unwrap(topics.TOPIC_REQUESTS, message, contract, store)
    assert request_id == message["request_id"]


@pytest.mark.parametrize("version", [1, "1", "v1.0"])
def test_version_must_be_major_dot_minor(contract, version):
    with pytest.raises(ContractError):
        contract.validate_envelope(example("orders.transition") | {"version": version})


async def test_an_unsupported_major_is_a_contract_error(contract, store):
    with pytest.raises(ContractError, match="unsupported"):
        await envelope.unwrap(topics.TOPIC_REQUESTS, example("orders.transition") | {"version": "2.0"}, contract, store)
    # A newer minor only adds optional fields.
    await envelope.unwrap(topics.TOPIC_REQUESTS, example("orders.transition") | {"version": "1.4"}, contract, store)


def test_every_handled_event_rides_a_shared_lane():
    assert set(topics.TOPIC_FOR.values()) <= {topics.TOPIC_UPLOADS, topics.TOPIC_REQUESTS, topics.TOPIC_RESULTS}
    assert all(event.startswith("apparule.") for event in topics.TOPIC_FOR)
