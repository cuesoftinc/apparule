"""The mediapipe_2d_v2 estimator: every A-10 template measure from a front and
a side view (capture-qc.md §3-§4, flows/vault.md A-10b).

Lengths come from the front view's landmarks. Girths combine the front
view's width with the side view's depth at the same body row, read from each
view's segmentation mask, as an ellipse. Each view has its own scale (its own
nose-to-ankle height against the user's height). The constants are in
app.config.Calibration and are uncalibrated until the two-view benchmark.
"""

import math
from collections.abc import Callable
from dataclasses import dataclass

import numpy as np

from app.config import Calibration, QCThresholds
from measurement import geometry as g
from pose.detector import Detection
from qc.pose import shoulder_hip_ratio


@dataclass
class View:
    detection: Detection
    sharpness: float

    @property
    def lm(self):
        return self.detection.landmarks

    def px_y(self, i: int) -> float:
        return self.lm[i].y * self.detection.height

    def px_x(self, i: int) -> float:
        return self.lm[i].x * self.detection.width

    def mid_y(self, a: int, b: int) -> float:
        return (self.px_y(a) + self.px_y(b)) / 2

    def mid_x(self, a: int, b: int) -> float:
        return (self.px_x(a) + self.px_x(b)) / 2

    @property
    def shoulder_y(self) -> float:
        return self.mid_y(g.LEFT_SHOULDER, g.RIGHT_SHOULDER)

    @property
    def hip_y(self) -> float:
        return self.mid_y(g.LEFT_HIP, g.RIGHT_HIP)

    @property
    def knee_y(self) -> float:
        return self.mid_y(g.LEFT_KNEE, g.RIGHT_KNEE)

    @property
    def ankle_y(self) -> float:
        return max(self.px_y(g.LEFT_ANKLE), self.px_y(g.RIGHT_ANKLE))

    def torso_row(self, fraction: float) -> float:
        return self.shoulder_y + fraction * (self.hip_y - self.shoulder_y)

    @property
    def body_center_x(self) -> float:
        return (self.mid_x(g.LEFT_SHOULDER, g.RIGHT_SHOULDER) + self.mid_x(g.LEFT_HIP, g.RIGHT_HIP)) / 2

    def run_width(self, y: float, x: float) -> float | None:
        """Width in pixels of the person's run of mask pixels on row `y` that
        contains column `x`, or the nearest run to it. None when the row is
        empty."""
        mask = self.detection.mask
        if mask is None:
            return None
        row = int(round(y))
        if not 0 <= row < mask.shape[0]:
            return None
        cols = np.flatnonzero(mask[row])
        if cols.size == 0:
            return None
        # Split the row's person pixels into contiguous runs.
        breaks = np.flatnonzero(np.diff(cols) > 1)
        starts = np.concatenate(([cols[0]], cols[breaks + 1]))
        ends = np.concatenate((cols[breaks], [cols[-1]]))
        col = int(round(x))
        inside = np.flatnonzero((starts <= col) & (col <= ends))
        if inside.size:
            k = int(inside[0])
        else:
            k = int(np.argmin(np.minimum(np.abs(starts - col), np.abs(ends - col))))
        return float(ends[k] - starts[k] + 1)

    def crotch_y(self) -> float | None:
        """The first row below the hips where the mask opens between the legs."""
        mask = self.detection.mask
        if mask is None:
            return None
        x = int(round(self.mid_x(g.LEFT_HIP, g.RIGHT_HIP)))
        if not 0 <= x < mask.shape[1]:
            return None
        start = int(round(self.hip_y))
        stop = int(round(self.knee_y))
        column = mask[start:stop, x]
        gaps = np.flatnonzero(~column)
        if gaps.size == 0:
            return None
        return float(start + gaps[0])


def ellipse_circumference(width: float, depth: float) -> float:
    """Ramanujan's approximation for an ellipse with these axes."""
    a, b = width / 2, depth / 2
    return math.pi * (3 * (a + b) - math.sqrt((3 * a + b) * (a + 3 * b)))


@dataclass
class Estimate:
    value_cm: float
    # Landmarks that define the measure, per view, for confidence.
    front: tuple[int, ...]
    side: tuple[int, ...] = ()


class Estimator:
    def __init__(self, front: View, side: View, height_cm: float, cal: Calibration, qc: QCThresholds):
        self.front = front
        self.side = side
        self.cal = cal
        self.qc = qc
        stature = height_cm * cal.stature_correction
        self.scale_front = stature / g.calculate_body_height_pixels(front.lm, front.detection.width, front.detection.height)
        self.scale_side = stature / g.calculate_body_height_pixels(side.lm, side.detection.width, side.detection.height)
        self._rules: dict[str, Callable[[], Estimate | None]] = {
            "shoulder": self.shoulder,
            "bust": lambda: self.girth(cal.bust_row),
            "chest": lambda: self.girth(cal.bust_row),
            "under_bust": lambda: self.girth(cal.under_bust_row),
            "waist": lambda: self.girth(cal.waist_row),
            "hip": lambda: self.girth(cal.hip_row),
            "neck": lambda: self.girth(cal.neck_row, landmarks=(g.NOSE, g.LEFT_SHOULDER, g.RIGHT_SHOULDER)),
            "bust_span": self.bust_span,
            "shoulder_to_bust_point": lambda: self.drop(cal.bust_row),
            "shoulder_to_under_bust": lambda: self.drop(cal.under_bust_row),
            "shoulder_to_waist": lambda: self.drop(cal.waist_row),
            "half_length": lambda: self.drop(1.0),
            "top_length": lambda: self.drop(cal.top_length_row),
            "gown_length": lambda: self.vertical(self.neck_y, front.ankle_y, (g.NOSE, *SHOULDERS, *ANKLES)),
            "skirt_length": self.waist_to_ankle,
            "trouser_length": self.waist_to_ankle,
            "waist_to_knee": lambda: self.vertical(front.torso_row(cal.waist_row), front.knee_y, (*SHOULDERS, *HIPS, *KNEES)),
            "trouser_inseam": self.inseam,
            "thigh": self.thigh,
            "knee": self.knee,
            "shin": self.shin,
            "sleeve_length": self.sleeve_length,
            "biceps": self.biceps,
            "sleeve_width": self.biceps,
        }

    def supports(self, name: str) -> bool:
        return name in self._rules

    def estimate(self, name: str) -> Estimate | None:
        rule = self._rules.get(name)
        return rule() if rule else None

    # -- rules ---------------------------------------------------------------

    @property
    def neck_y(self) -> float:
        return self.front.torso_row(self.cal.neck_row)

    def shoulder(self) -> Estimate:
        f = self.front
        px = g.calculate_shoulder_width(f.lm, f.detection.width, f.detection.height)
        return Estimate(px * self.scale_front, SHOULDERS)

    def girth(self, fraction: float, landmarks: tuple[int, ...] = ()) -> Estimate | None:
        width = self.front.run_width(self.front.torso_row(fraction), self.front.body_center_x)
        depth = self.side.run_width(self.side.torso_row(fraction), self.side.body_center_x)
        if width is None or depth is None:
            return None
        cm = ellipse_circumference(width * self.scale_front, depth * self.scale_side)
        used = landmarks or (*SHOULDERS, *HIPS)
        return Estimate(cm, used, used)

    def bust_span(self) -> Estimate | None:
        width = self.front.run_width(self.front.torso_row(self.cal.bust_row), self.front.body_center_x)
        if width is None:
            return None
        return Estimate(width * self.scale_front * self.cal.bust_span_fraction, (*SHOULDERS, *HIPS))

    def drop(self, fraction: float) -> Estimate:
        """From the neck base down to a torso row."""
        return self.vertical(self.neck_y, self.front.torso_row(fraction), (g.NOSE, *SHOULDERS, *HIPS))

    def vertical(self, top_y: float, bottom_y: float, landmarks: tuple[int, ...]) -> Estimate:
        return Estimate(abs(bottom_y - top_y) * self.scale_front, landmarks)

    def waist_to_ankle(self) -> Estimate:
        return self.vertical(self.front.torso_row(self.cal.waist_row), self.front.ankle_y, (*SHOULDERS, *HIPS, *ANKLES))

    def inseam(self) -> Estimate | None:
        crotch = self.front.crotch_y()
        if crotch is None:
            return None
        return self.vertical(crotch, self.front.ankle_y, (*HIPS, *KNEES, *ANKLES))

    def _leg_girth(self, y_front: float, y_side: float, landmarks: tuple[int, ...]) -> Estimate | None:
        f, s = self.front, self.side
        # The left leg's centre on the front view; legs overlap in profile.
        x_front = (f.px_x(g.LEFT_HIP) + f.px_x(g.LEFT_KNEE)) / 2 if y_front < f.knee_y else f.px_x(g.LEFT_KNEE)
        x_side = (s.px_x(g.LEFT_HIP) + s.px_x(g.LEFT_KNEE)) / 2 if y_side < s.knee_y else s.px_x(g.LEFT_KNEE)
        width = f.run_width(y_front, x_front)
        depth = s.run_width(y_side, x_side)
        if width is None or depth is None:
            return None
        return Estimate(ellipse_circumference(width * self.scale_front, depth * self.scale_side), landmarks, landmarks)

    def thigh(self) -> Estimate | None:
        f, s, t = self.front, self.side, self.cal.thigh_row
        return self._leg_girth(f.hip_y + t * (f.knee_y - f.hip_y), s.hip_y + t * (s.knee_y - s.hip_y), (*HIPS, *KNEES))

    def knee(self) -> Estimate | None:
        return self._leg_girth(self.front.knee_y, self.side.knee_y, KNEES)

    def shin(self) -> Estimate:
        f = self.front
        return Estimate(g.calculate_shin_length(f.lm, f.detection.width, f.detection.height) * self.scale_front, (*KNEES, *ANKLES))

    def sleeve_length(self) -> Estimate:
        f = self.front
        return Estimate(g.calculate_sleeve_length(f.lm, f.detection.width, f.detection.height) * self.scale_front, ARMS)

    def biceps(self) -> Estimate | None:
        """The upper arm's width on the front view, taken as round: in profile
        the arm hangs against the torso, so there is no separate depth."""
        f = self.front
        y = f.mid_y(g.LEFT_SHOULDER, g.LEFT_ELBOW)
        x = f.mid_x(g.LEFT_SHOULDER, g.LEFT_ELBOW)
        width = f.run_width(y, x)
        if width is None:
            return None
        return Estimate(math.pi * width * self.scale_front, (g.LEFT_SHOULDER, g.LEFT_ELBOW))

    # -- §3 / §4 -------------------------------------------------------------

    def height_suspect(self) -> bool:
        f = self.front
        stature_px = g.calculate_body_height_pixels(f.lm, f.detection.width, f.detection.height) / self.cal.stature_correction
        ratio = (f.hip_y - f.shoulder_y) / stature_px
        return not self.cal.torso_ratio_min <= ratio <= self.cal.torso_ratio_max

    def confidence(self, est: Estimate) -> float:
        """capture-qc.md §4, spanning both views for two-view measures:
        mean visibility over the defining landmarks of each view used, times
        the frontality factor, times the weaker view's sharpness factor."""
        vis = [self.front.lm[i].visibility for i in est.front] + [self.side.lm[i].visibility for i in est.side]
        mean_vis = sum(vis) / len(vis) if vis else 0.0
        ratio = shoulder_hip_ratio(self.front.detection)
        frontality = 1.0 if self.qc.confident_ratio_min <= ratio <= self.qc.confident_ratio_max else 0.85
        views = [self.front] + ([self.side] if est.side else [])
        sharpness = min(1.0 if v.sharpness >= self.qc.sharp_laplacian_var else 0.9 for v in views)
        return round(max(0.0, min(1.0, mean_vis * frontality * sharpness)), 2)


SHOULDERS = (g.LEFT_SHOULDER, g.RIGHT_SHOULDER)
HIPS = (g.LEFT_HIP, g.RIGHT_HIP)
KNEES = (g.LEFT_KNEE, g.RIGHT_KNEE)
ANKLES = (g.LEFT_ANKLE, g.RIGHT_ANKLE)
ARMS = (g.LEFT_SHOULDER, g.RIGHT_SHOULDER, g.LEFT_ELBOW, g.RIGHT_ELBOW, g.LEFT_WRIST, g.RIGHT_WRIST)
