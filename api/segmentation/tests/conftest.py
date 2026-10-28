import json
import os
from pathlib import Path

import numpy as np
import pytest

# Settings fail fast without these; tests never reach Kafka or storage.
os.environ.setdefault("KAFKA_BROKERS", "localhost:9094")
os.environ.setdefault("STORAGE_BUCKET", "test-bucket")
os.environ.setdefault("STORAGE_PREFIX", "apparule/test")

from contract import Contract  # noqa: E402
from pose.detector import Detection, Landmark  # noqa: E402
from storage import ObjectMissing  # noqa: E402

# In the image the schemas are copied to ./contract; in the repo they live
# in api/common/contract.
CONTRACT_DIR = Path(os.environ.get("CONTRACT_DIR", Path(__file__).resolve().parents[2] / "common" / "contract"))


class MemoryStore:
    bucket = "test-bucket"

    def __init__(self):
        self.objects: dict[str, bytes] = {}

    async def get(self, key: str) -> bytes:
        if key not in self.objects:
            raise ObjectMissing(key)
        return self.objects[key]

    async def put(self, key: str, data: bytes, content_type: str) -> None:
        self.objects[key] = data


@pytest.fixture(scope="session")
def contract() -> Contract:
    return Contract(CONTRACT_DIR)


@pytest.fixture
def store() -> MemoryStore:
    return MemoryStore()


def example(name: str) -> dict:
    return json.loads((CONTRACT_DIR / "examples" / f"{name}.json").read_text(encoding="utf-8"))


# -- a synthetic person ------------------------------------------------------
#
# A 1000 x 1600 image with a standing figure: landmarks placed where
# MediaPipe would put them, and a mask drawn as torso, legs and arms. `side`
# turns the figure: shoulders foreshortened and one shoulder deeper.

W, H = 1000, 1600


def person(pose: str = "front", **moves: tuple[float, float]) -> Detection:
    side = pose == "side"
    half_shoulder = 0.05 if side else 0.11
    half_hip = 0.07 if side else 0.08
    points = {
        0: (0.50, 0.12),  # nose
        11: (0.50 + half_shoulder, 0.25),
        12: (0.50 - half_shoulder, 0.25),
        13: (0.50 + half_shoulder + 0.03, 0.40),
        14: (0.50 - half_shoulder - 0.03, 0.40),
        15: (0.50 + (0.10 if side else 0.20), 0.53),
        16: (0.50 - (0.10 if side else 0.20), 0.53),
        23: (0.50 + half_hip, 0.52),
        24: (0.50 - half_hip, 0.52),
        25: (0.50 + half_hip, 0.72),
        26: (0.50 - half_hip, 0.72),
        27: (0.50 + half_hip, 0.92),
        28: (0.50 - half_hip, 0.92),
    }
    points.update({int(i): xy for i, xy in moves.items()})
    landmarks = [Landmark(0.5, 0.5, 0.0, 0.0) for _ in range(33)]
    for i, (x, y) in points.items():
        z = 0.0
        if i == 11:
            z = -0.2 if side else -0.02
        if i == 12:
            z = 0.0
        landmarks[i] = Landmark(x, y, z, 0.95)

    mask = np.zeros((H, W), dtype=bool)
    torso = 0.08 if side else 0.12
    mask[int(0.08 * H) : int(0.17 * H), int(0.46 * W) : int(0.54 * W)] = True  # head
    mask[int(0.17 * H) : int(0.22 * H), int(0.47 * W) : int(0.53 * W)] = True  # neck
    mask[int(0.22 * H) : int(0.60 * H), int((0.5 - torso) * W) : int((0.5 + torso) * W)] = True  # torso
    leg = 0.035 if not side else 0.05
    for cx in (0.5,) if side else (0.42, 0.58):
        mask[int(0.60 * H) : int(0.94 * H), int((cx - leg) * W) : int((cx + leg) * W)] = True  # legs
    if not side:
        for sign in (1, -1):  # arms, clear of the torso
            x0 = 0.5 + sign * 0.17
            lo, hi = sorted((x0 - 0.025, x0 + 0.025))
            mask[int(0.25 * H) : int(0.55 * H), int(lo * W) : int(hi * W)] = True
    return Detection(W, H, 1, landmarks, mask)


class FakeAnalyzer:
    """Returns the queued detections in order, one per analyzed image."""

    def __init__(self, *detections: Detection):
        self.queue = list(detections)

    def analyze(self, bgr):
        return self.queue.pop(0)

    def close(self):
        pass
