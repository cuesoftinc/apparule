"""§2 pose QC, after detection. The first failure in table order wins.

The front pose checks both sides of the body. The side pose checks the side
facing the camera: in a true profile the far shoulder, hip, wrist and ankle
are hidden behind the body, and the model only guesses where they are, so no
rule may depend on them. Either profile (left or right side to the camera)
is accepted; measuring doesn't depend on which.
"""

import math

from app.config import QCThresholds
from measurement import geometry as g
from pose.detector import Detection

SHOULDERS = (g.LEFT_SHOULDER, g.RIGHT_SHOULDER)
HIPS = (g.LEFT_HIP, g.RIGHT_HIP)
ANKLES = (g.LEFT_ANKLE, g.RIGHT_ANKLE)
FRONT_KEY = (g.NOSE,) + SHOULDERS + HIPS + ANKLES

# One side of the body: shoulder, hip, ankle, wrist, knee, elbow.
LEFT = {"shoulder": g.LEFT_SHOULDER, "hip": g.LEFT_HIP, "ankle": g.LEFT_ANKLE, "wrist": g.LEFT_WRIST, "knee": g.LEFT_KNEE, "elbow": g.LEFT_ELBOW}
RIGHT = {"shoulder": g.RIGHT_SHOULDER, "hip": g.RIGHT_HIP, "ankle": g.RIGHT_ANKLE, "wrist": g.RIGHT_WRIST, "knee": g.RIGHT_KNEE, "elbow": g.RIGHT_ELBOW}


def near_side(d: Detection) -> dict[str, int]:
    """The side of the body facing the camera: the one the model sees more
    clearly, and on a tie the one nearer the camera (smaller z)."""
    lm = d.landmarks

    def seen(side: dict[str, int]) -> float:
        return sum(lm[side[k]].visibility for k in ("shoulder", "hip", "ankle"))

    left, right = seen(LEFT), seen(RIGHT)
    if abs(left - right) > 0.1:
        return LEFT if left > right else RIGHT
    return LEFT if lm[g.LEFT_SHOULDER].z <= lm[g.RIGHT_SHOULDER].z else RIGHT


def key_landmarks(d: Detection, pose: str) -> tuple[int, ...]:
    """What must be visible and in frame: the whole body facing the camera,
    or the head and the camera-side shoulder, hip and ankle in profile."""
    if pose == "front":
        return FRONT_KEY
    side = near_side(d)
    return (g.NOSE, side["shoulder"], side["hip"], side["ankle"])


def shoulder_hip_ratio(d: Detection) -> float:
    lm = d.landmarks
    hip = g.calculate_hip_width(lm, d.width, d.height)
    if hip <= 0:
        return math.inf
    return g.calculate_shoulder_width(lm, d.width, d.height) / hip


def shoulder_z_delta(d: Detection) -> float:
    return abs(d.landmarks[g.LEFT_SHOULDER].z - d.landmarks[g.RIGHT_SHOULDER].z)


def shoulder_span_ratio(d: Detection) -> float:
    """Shoulder span over torso length, in pixels: about 0.5 facing the
    camera, near 0.1 in profile. Unlike shoulder/hip width (both shrink in
    profile) it separates the two poses."""
    lm = d.landmarks
    span = g.calculate_shoulder_width(lm, d.width, d.height)
    _, shoulder_y = g.midpoint(lm[g.LEFT_SHOULDER], lm[g.RIGHT_SHOULDER])
    _, hip_y = g.midpoint(lm[g.LEFT_HIP], lm[g.RIGHT_HIP])
    torso = abs(hip_y - shoulder_y) * d.height
    return span / torso if torso > 0 else math.inf


def tilt_degrees(d: Detection, ankle_x: float, ankle_y: float) -> float:
    """Angle of the nose-to-ankle axis from vertical, in pixels."""
    nose = d.landmarks[g.NOSE]
    dx = (ankle_x - nose.x) * d.width
    dy = (ankle_y - nose.y) * d.height
    return abs(math.degrees(math.atan2(dx, dy)))


def check(d: Detection, pose: str, qc: QCThresholds) -> str | None:
    if d.people == 0:
        return "no_body"
    if d.people > 1:
        return "multiple_bodies"
    lm = d.landmarks
    key = key_landmarks(d, pose)
    if min(lm[i].visibility for i in key) < qc.min_key_visibility:
        return "partial_body"
    lo, hi = qc.margin, 1 - qc.margin
    if any(not (lo <= lm[i].x <= hi and lo <= lm[i].y <= hi) for i in key):
        return "partial_body"

    span = shoulder_span_ratio(d)
    if pose == "front":
        ratio = shoulder_hip_ratio(d)
        if not (qc.frontal_ratio_min <= ratio <= qc.frontal_ratio_max and shoulder_z_delta(d) <= qc.shoulder_z_delta and span >= qc.profile_span_max):
            return "not_frontal"
        ankle_x, ankle_y = g.midpoint(lm[g.LEFT_ANKLE], lm[g.RIGHT_ANKLE])
    else:
        if span >= qc.profile_span_max:
            return "not_side_profile"
        side = near_side(d)
        ankle_x, ankle_y = lm[side["ankle"]].x, lm[side["ankle"]].y

    if tilt_degrees(d, ankle_x, ankle_y) > qc.max_tilt_degrees:
        return "camera_tilt"

    if pose == "front":
        # Arms slightly out, so the torso's outline is clear of them.
        gaps = (abs(lm[g.LEFT_WRIST].x - lm[g.LEFT_HIP].x), abs(lm[g.RIGHT_WRIST].x - lm[g.RIGHT_HIP].x))
        if min(gaps) < qc.arms_clearance:
            return "arms_position"
    else:
        # Arms relaxed at the sides: the camera-side wrist hangs by the hip.
        side = near_side(d)
        if abs(lm[side["wrist"]].x - lm[side["hip"]].x) > qc.arms_clearance:
            return "arms_position"

    body_height = abs(ankle_y - lm[g.NOSE].y) * d.height
    if body_height < qc.min_body_height_fraction * d.height:
        return "too_far"
    return None
