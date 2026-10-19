import cv2
import numpy as np
import pytest

from app.config import QC
from pose.detector import Detection
from qc import image as image_qc
from qc import pose as pose_qc
from tests.conftest import person


def _jpeg(img: np.ndarray) -> bytes:
    ok, buf = cv2.imencode(".jpg", img)
    assert ok
    return buf.tobytes()


def _textured(h: int, w: int, mean: int) -> np.ndarray:
    rng = np.random.default_rng(1)
    noise = rng.integers(-40, 40, size=(h, w, 3))
    return np.clip(mean + noise, 0, 255).astype(np.uint8)


def test_undecodable():
    assert image_qc.precheck(b"not an image", QC).code == "undecodable_image"


def test_low_resolution():
    assert image_qc.precheck(_jpeg(_textured(400, 300, 128)), QC).code == "low_resolution"


@pytest.mark.parametrize("mean", [10, 245])
def test_poor_lighting(mean):
    flat = np.full((800, 600, 3), mean, dtype=np.uint8)
    assert image_qc.precheck(_jpeg(flat), QC).code == "poor_lighting"


def test_blurry():
    smooth = cv2.GaussianBlur(_textured(800, 600, 128), (51, 51), 20)
    assert image_qc.precheck(_jpeg(smooth), QC).code == "blurry"


def test_sharp_image_passes_and_reports_sharpness():
    check = image_qc.precheck(_jpeg(_textured(800, 600, 128)), QC)
    assert check.code is None and check.sharpness >= QC.min_laplacian_var


def test_front_pose_passes():
    assert pose_qc.check(person("front"), "front", QC) is None


def test_side_pose_passes():
    assert pose_qc.check(person("side"), "side", QC) is None


def test_no_body_and_multiple_bodies():
    empty = Detection(1000, 1600, 0, [], None)
    assert pose_qc.check(empty, "front", QC) == "no_body"
    two = person("front")
    two.people = 2
    assert pose_qc.check(two, "front", QC) == "multiple_bodies"


def test_partial_body_by_visibility_and_margin():
    hidden = person("front")
    hidden.landmarks[27].visibility = 0.2
    assert pose_qc.check(hidden, "front", QC) == "partial_body"
    cut = person("front", **{"27": (0.58, 0.995)})
    assert pose_qc.check(cut, "front", QC) == "partial_body"


def test_front_rejects_a_side_on_body_and_side_rejects_a_frontal_one():
    assert pose_qc.check(person("side"), "front", QC) == "not_frontal"
    assert pose_qc.check(person("front"), "side", QC) == "not_side_profile"


def test_camera_tilt():
    # 0.45 of 1000 px over 1280 px of body: ~19 degrees off vertical.
    tilted = person("front", **{"0": (0.05, 0.12)})
    assert pose_qc.check(tilted, "front", QC) == "camera_tilt"


def test_arms_position_differs_per_pose():
    tucked = person("front", **{"15": (0.59, 0.53), "16": (0.41, 0.53)})
    assert pose_qc.check(tucked, "front", QC) == "arms_position"
    reaching = person("side", **{"15": (0.70, 0.53)})
    assert pose_qc.check(reaching, "side", QC) == "arms_position"


def test_too_far():
    small = person("front")
    for lm in small.landmarks:
        lm.y = 0.4 + (lm.y - 0.5) * 0.4
    assert pose_qc.check(small, "front", QC) == "too_far"


def test_first_failure_in_table_order():
    # Both partial (an ankle hidden) and tilted: partial_body comes first.
    both = person("front", **{"0": (0.30, 0.12)})
    both.landmarks[28].visibility = 0.1
    assert pose_qc.check(both, "front", QC) == "partial_body"
