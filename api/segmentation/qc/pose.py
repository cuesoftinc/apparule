"""§2 pose QC, after detection. The front and side poses share most rows; the
orientation and arms rows differ. The first failure in table order wins."""

import math

from app.config import QCThresholds
from measurement import geometry as g
from pose.detector import Detection

HEAD = (g.NOSE,)
SHOULDERS = (g.LEFT_SHOULDER, g.RIGHT_SHOULDER)
HIPS = (g.LEFT_HIP, g.RIGHT_HIP)
ANKLES = (g.LEFT_ANKLE, g.RIGHT_ANKLE)
KEY = HEAD + SHOULDERS + HIPS + ANKLES


def shoulder_hip_ratio(d: Detection) -> float:
    lm = d.landmarks
    hip = g.calculate_hip_width(lm, d.width, d.height)
    if hip <= 0:
        return math.inf
    return g.calculate_shoulder_width(lm, d.width, d.height) / hip


def shoulder_z_delta(d: Detection) -> float:
    return abs(d.landmarks[g.LEFT_SHOULDER].z - d.landmarks[g.RIGHT_SHOULDER].z)


def tilt_degrees(d: Detection) -> float:
    """Angle of the nose-to-ankle-midpoint axis from vertical, in pixels."""
    lm = d.landmarks
    nose = lm[g.NOSE]
    ax, ay = g.midpoint(lm[g.LEFT_ANKLE], lm[g.RIGHT_ANKLE])
    dx = (ax - nose.x) * d.width
    dy = (ay - nose.y) * d.height
    return abs(math.degrees(math.atan2(dx, dy)))


def _wrist_hip_gaps(d: Detection) -> tuple[float, float]:
    lm = d.landmarks
    return (
        abs(lm[g.LEFT_WRIST].x - lm[g.LEFT_HIP].x),
        abs(lm[g.RIGHT_WRIST].x - lm[g.RIGHT_HIP].x),
    )


def check(d: Detection, pose: str, qc: QCThresholds) -> str | None:
    if d.people == 0:
        return "no_body"
    if d.people > 1:
        return "multiple_bodies"
    lm = d.landmarks
    if min(lm[i].visibility for i in KEY) < qc.min_key_visibility:
        return "partial_body"
    lo, hi = qc.margin, 1 - qc.margin
    if any(not (lo <= lm[i].x <= hi and lo <= lm[i].y <= hi) for i in KEY):
        return "partial_body"

    ratio = shoulder_hip_ratio(d)
    z_delta = shoulder_z_delta(d)
    if pose == "front":
        if not (qc.frontal_ratio_min <= ratio <= qc.frontal_ratio_max and z_delta <= qc.shoulder_z_delta):
            return "not_frontal"
    elif not (z_delta >= qc.shoulder_z_delta and ratio < qc.frontal_ratio_min):
        return "not_side_profile"

    if tilt_degrees(d) > qc.max_tilt_degrees:
        return "camera_tilt"

    gaps = _wrist_hip_gaps(d)
    if pose == "front":
        # Arms slightly out, so the torso's outline is clear of them.
        if min(gaps) < qc.arms_clearance:
            return "arms_position"
    elif max(gaps) > qc.arms_clearance:
        # Arms relaxed at the sides.
        return "arms_position"

    body_height = g.calculate_body_height_pixels(lm, d.width, d.height)
    if body_height < qc.min_body_height_fraction * d.height:
        return "too_far"
    return None
