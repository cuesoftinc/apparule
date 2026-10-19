import math

import pytest

from app.config import CALIBRATION, QC
from measurement.estimate import Estimator, View, ellipse_circumference
from tests.conftest import example, person

TEMPLATES = {
    "women": [m["name"] for m in example("capture.ready")["data"]["measures"]],
    "men": ["shoulder", "chest", "waist", "top_length", "thigh", "hip", "knee", "shin", "waist_to_knee",
            "trouser_length", "trouser_inseam", "biceps", "sleeve_length", "neck"],
}


def _estimator(height_cm: float = 170) -> Estimator:
    return Estimator(View(person("front"), 150.0), View(person("side"), 150.0), height_cm, CALIBRATION, QC)


def test_circle_is_a_special_ellipse():
    assert ellipse_circumference(10, 10) == pytest.approx(math.pi * 10)


def test_run_width_finds_the_run_under_the_point():
    front = View(person("front"), 150.0)
    torso_row = front.torso_row(0.5)
    # Torso spans 0.38-0.62 of 1000 px; the arms are separate runs.
    assert front.run_width(torso_row, front.body_center_x) == pytest.approx(240, abs=2)
    assert front.run_width(torso_row, 0.67 * 1000) == pytest.approx(50, abs=2)
    assert front.run_width(10, 500) is None  # empty row


def test_crotch_is_where_the_legs_part():
    front = View(person("front"), 150.0)
    assert front.crotch_y() == pytest.approx(0.60 * 1600, abs=2)


@pytest.mark.parametrize("template", ["women", "men"])
def test_every_template_measure_has_an_estimator(template):
    est = _estimator()
    for name in TEMPLATES[template]:
        assert est.supports(name), name
        value = est.estimate(name)
        assert value is not None and value.value_cm > 0, name


def test_values_scale_with_height():
    short, tall = _estimator(150), _estimator(180)
    for name in ("waist", "sleeve_length", "trouser_length"):
        assert tall.estimate(name).value_cm / short.estimate(name).value_cm == pytest.approx(180 / 150)


def test_girth_uses_front_width_and_side_depth():
    est = _estimator()
    waist = est.estimate("waist")
    width = 240 * est.scale_front
    depth = 160 * est.scale_side
    assert waist.value_cm == pytest.approx(ellipse_circumference(width, depth), rel=0.02)


def test_confidence_in_unit_range_and_sharpness_lowers_it():
    sharp = _estimator()
    soft = Estimator(View(person("front"), 80.0), View(person("side"), 80.0), 170, CALIBRATION, QC)
    a = sharp.confidence(sharp.estimate("waist"))
    b = soft.confidence(soft.estimate("waist"))
    assert 0 <= b < a <= 1
    assert b == pytest.approx(a * 0.9, abs=0.01)


def test_height_suspect_flags_an_implausible_torso():
    assert _estimator().height_suspect() is False
    stretched = person("front", **{"23": (0.58, 0.85), "24": (0.42, 0.85)})
    est = Estimator(View(stretched, 150.0), View(person("side"), 150.0), 170, CALIBRATION, QC)
    assert est.height_suspect() is True
