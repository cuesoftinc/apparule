import cv2
import numpy as np

from kafka import topics
from pipeline import CapturePipeline
from tests.conftest import FakeAnalyzer, example, person


def _photo() -> bytes:
    rng = np.random.default_rng(7)
    img = np.clip(128 + rng.integers(-40, 40, size=(1600, 1000, 3)), 0, 255).astype(np.uint8)
    return cv2.imencode(".jpg", img)[1].tobytes()


def _ready(store, *, poses=("front", "side")) -> dict:
    msg = example("capture.ready")["data"]
    for pose in poses:
        store.objects[msg["poses"][pose]["object"]["key"]] = _photo()
    return msg


async def test_measures_every_template_measure(store, contract):
    msg = _ready(store)
    result = await CapturePipeline(store, FakeAnalyzer(person("front"), person("side"))).run(msg)
    contract.validate_data(topics.CAPTURE_MEASURED, result)
    assert result["status"] == "measured"
    assert result["poses"] == {"front": "accepted", "side": "accepted"}
    assert [m["name"] for m in result["measurements"]] == [m["name"] for m in msg["measures"]]
    assert result["attempt"] == msg["attempt"] and result["method"] == "mediapipe_2d_v2"


async def test_side_failure_keeps_the_front_pose(store, contract):
    msg = _ready(store)
    result = await CapturePipeline(store, FakeAnalyzer(person("front"), person("front"))).run(msg)
    contract.validate_data(topics.CAPTURE_MEASURED, result)
    assert result["status"] == "failed_qc"
    assert result["qc"] == {"code": "not_side_profile", "pose": "side"}
    assert result["poses"] == {"front": "accepted", "side": "failed"}
    assert "measurements" not in result


async def test_front_failure_is_reported_first(store):
    msg = _ready(store)
    result = await CapturePipeline(store, FakeAnalyzer(person("side"), person("front"))).run(msg)
    assert result["qc"] == {"code": "not_frontal", "pose": "front"}
    assert result["poses"] == {"front": "failed", "side": "failed"}


async def test_undecodable_image_fails_its_pose(store):
    msg = _ready(store)
    store.objects[msg["poses"]["side"]["object"]["key"]] = b"garbage"
    result = await CapturePipeline(store, FakeAnalyzer(person("front"))).run(msg)
    assert result["qc"] == {"code": "undecodable_image", "pose": "side"}
    assert result["poses"]["front"] == "accepted"


async def test_missing_image_fails_without_qc(store, contract):
    msg = _ready(store, poses=("front",))
    result = await CapturePipeline(store, FakeAnalyzer()).run(msg)
    contract.validate_data(topics.CAPTURE_MEASURED, result)
    assert result["status"] == "failed" and result["error_code"] == "image_missing"


async def test_unknown_measure_is_skipped(store):
    msg = _ready(store)
    msg["measures"] = msg["measures"][:2] + [{"name": "wingspan_of_cape", "min": 1, "max": 2}]
    result = await CapturePipeline(store, FakeAnalyzer(person("front"), person("side"))).run(msg)
    assert [m["name"] for m in result["measurements"]] == [m["name"] for m in msg["measures"][:2]]
