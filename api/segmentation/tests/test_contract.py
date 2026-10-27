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


def test_rejects_unknown_field(contract):
    data = example("capture.measured")["data"] | {"surprise": True}
    with pytest.raises(ContractError, match="surprise"):
        contract.validate_data(topics.CAPTURE_MEASURED, data)


def test_failed_qc_needs_its_code(contract):
    data = example("capture.measured.failed_qc")["data"]
    del data["qc"]
    with pytest.raises(ContractError):
        contract.validate_data(topics.CAPTURE_MEASURED, data)


async def test_every_payload_goes_by_reference(contract, store):
    """The bus is shared with other products (system-design.md §5.3)."""
    data = example("capture.measured")["data"]
    message = await envelope.wrap(topics.CAPTURE_MEASURED, data, contract, store, "apparule/test", "s:1")
    assert "data" not in message and message["data_ref"]["key"].startswith("apparule/test/compute/")
    assert message["version"] == "1.0" and message["request_id"] == "s:1"
    # Measurement values never ride the bus itself.
    assert "value_cm" not in json.dumps(message)
    assert await envelope.unwrap(topics.TOPIC_RESULTS, message, contract, store) == (topics.CAPTURE_MEASURED, data, "s:1")


async def test_unwrap_rejects_wrong_topic(contract, store):
    with pytest.raises(ValueError):
        await envelope.unwrap(topics.TOPIC_REQUESTS, example("capture.measured"), contract, store)


@pytest.mark.parametrize("version", [1, "1", "v1.0"])
def test_version_must_be_major_dot_minor(contract, version):
    with pytest.raises(ContractError):
        contract.validate_envelope(example("capture.ready") | {"version": version})


async def test_an_unsupported_major_is_a_contract_error(contract, store):
    with pytest.raises(ContractError, match="unsupported"):
        await envelope.unwrap(topics.TOPIC_REQUESTS, example("capture.ready") | {"version": "2.0"}, contract, store)
    event, _, request_id = await envelope.unwrap(topics.TOPIC_REQUESTS, example("capture.ready") | {"version": "1.3"}, contract, store)
    assert event == topics.CAPTURE_READY and request_id == example("capture.ready")["request_id"]


def test_events_ride_the_shared_lanes():
    assert set(topics.TOPIC_FOR.values()) <= {topics.TOPIC_UPLOADS, topics.TOPIC_REQUESTS, topics.TOPIC_RESULTS}
    assert all(event.startswith("apparule.") for event in topics.TOPIC_FOR)


def test_other_products_messages_are_not_ours():
    assert envelope.event_of({"type": "expendit.import.ready"}) == "expendit.import.ready"
    assert envelope.event_of(None) is None  # undecodable bytes
    assert envelope.event_of({"no": "type"}) is None
