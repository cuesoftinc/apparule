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


def _person_mask(h: int, w: int) -> np.ndarray:
    mask = np.zeros((h, w), dtype=bool)
    mask[h // 4: 3 * h // 4, w // 3: 2 * w // 3] = True
    return mask


@pytest.mark.parametrize("mean", [10, 245])
def test_poor_lighting_on_the_person(mean):
    flat = np.full((800, 600, 3), mean, dtype=np.uint8)
    assert image_qc.quality(flat, _person_mask(800, 600), QC).code == "poor_lighting"


def test_a_well_lit_person_on_a_white_wall_passes():
    """The whole frame averages ~230 (overexposed by the old rule); the
    person is mid-grey and sharp."""
    img = np.full((800, 600, 3), 250, dtype=np.uint8)
    mask = _person_mask(800, 600)
    img[mask] = _textured(800, 600, 120)[mask]
    assert img.mean() > QC.max_luma
    check = image_qc.quality(img, mask, QC)
    assert check.code is None and QC.min_luma <= check.luma <= QC.max_luma


def test_blurry_person():
    smooth = cv2.GaussianBlur(_textured(800, 600, 128), (51, 51), 20)
    assert image_qc.quality(smooth, _person_mask(800, 600), QC).code == "blurry"


def test_sharp_person_on_a_plain_wall_passes():
    img = np.full((800, 600, 3), 200, dtype=np.uint8)
    mask = _person_mask(800, 600)
    img[mask] = _textured(800, 600, 128)[mask]
    check = image_qc.quality(img, mask, QC)
    assert check.code is None and check.sharpness >= QC.min_laplacian_var


def test_resolution_passes_before_detection():
    assert image_qc.precheck(_jpeg(_textured(800, 600, 128)), QC).code is None


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


def test_side_ignores_the_hidden_far_side():
    """In profile the far ankle, wrist and hip are behind the body; their
    visibility and guessed positions don't matter (the user's real photo:
    far ankle visibility 0.17)."""
    side = person("side")
    for i in (12, 24, 28, 16):  # right shoulder, hip, ankle, wrist (far side)
        side.landmarks[i].visibility = 0.1
    side.landmarks[16].x = 0.9  # a wild guess for the hidden wrist
    assert pose_qc.check(side, "side", QC) is None


def test_side_needs_the_camera_side_ankle():
    side = person("side")
    side.landmarks[27].visibility = 0.2  # near (left) ankle hidden
    side.landmarks[28].visibility = 0.1
    assert pose_qc.check(side, "side", QC) == "partial_body"


def test_either_profile_is_accepted():
    right = person("side")
    # Mirror the body: right side toward the camera.
    for lm in right.landmarks:
        lm.x = 1 - lm.x
    right.landmarks[11].z, right.landmarks[12].z = 0.0, -0.2
    for i in (11, 23, 27, 15):
        right.landmarks[i].visibility = 0.2
    assert pose_qc.near_side(right) is pose_qc.RIGHT
    assert pose_qc.check(right, "side", QC) is None


def test_front_rejects_a_side_on_body_and_side_rejects_a_frontal_one():
    assert pose_qc.check(person("side"), "front", QC) == "not_frontal"
    assert pose_qc.check(person("front"), "side", QC) == "not_side_profile"


def test_profile_is_judged_by_shoulder_span_not_shoulder_hip_ratio():
    """The user's real profile had a shoulder/hip width ratio of 1.48 (the
    old rule wanted < 0.9) but a shoulder span of ~0.1 of torso length."""
    # The real photo's spans: shoulders 0.037, hips 0.028 of the frame.
    side = person("side", **{"11": (0.527, 0.25), "12": (0.490, 0.25), "23": (0.507, 0.52), "24": (0.479, 0.52),
                             "15": (0.500, 0.53)})
    assert pose_qc.shoulder_hip_ratio(side) > QC.frontal_ratio_min
    assert pose_qc.shoulder_span_ratio(side) < QC.profile_span_max
    assert pose_qc.check(side, "side", QC) is None


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


def test_real_models_mask_is_two_dimensional():
    """The selfie segmenter's category mask is (h, w, 1); every caller needs
    (h, w). Runs the real models when they're present."""
    import os

    if not (os.path.exists("pose_landmarker.task") and os.path.exists("selfie_segmenter.tflite")):
        pytest.skip("model assets not present")
    from pose.detector import PoseAnalyzer

    analyzer = PoseAnalyzer("pose_landmarker.task", "selfie_segmenter.tflite")
    try:
        img = cv2.imread("demo/input/image_test2.jpeg")
        d = analyzer.analyze(img)
        assert d.people == 1 and d.mask is not None and d.mask.shape == img.shape[:2]
        assert image_qc.quality(img, d.mask, QC).code is None
    finally:
        analyzer.close()
