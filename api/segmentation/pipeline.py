"""capture.ready -> capture.measured (system-design.md §6.1).

Both poses run the pre-checks and pose QC; an accepted pose is reported as
accepted even when the other one fails, so common keeps it for the retake
(flows/vault.md §1). When both pass, every measure of the customer's template
is estimated. Image bytes and measurement values are never logged.
"""

import asyncio
import logging
import time

from app.config import CALIBRATION, QC, Calibration, QCThresholds
from measurement.estimate import Estimator, View
from pose.detector import PoseAnalyzer
from qc import image as image_qc
from qc import pose as pose_qc
from storage import ObjectMissing, ObjectStore

log = logging.getLogger(__name__)

METHOD = "mediapipe_2d_v2"
POSES = ("front", "side")


class CapturePipeline:
    def __init__(
        self,
        store: ObjectStore,
        analyzer: PoseAnalyzer,
        qc: QCThresholds = QC,
        calibration: Calibration = CALIBRATION,
        model_names: tuple[str, str] = ("pose_landmarker", "selfie_segmenter"),
    ):
        self._store = store
        self._analyzer = analyzer
        self._qc = qc
        self._cal = calibration
        self._models = model_names

    async def run(self, msg: dict) -> dict:
        start = time.monotonic()
        base = {
            "session_id": msg["session_id"],
            "attempt": msg["attempt"],
            "method": METHOD,
            "thresholds_version": self._qc.version,
        }
        images: dict[str, bytes] = {}
        try:
            for pose in POSES:
                images[pose] = await self._store.get(msg["poses"][pose]["object"]["key"])
        except ObjectMissing:
            # The bucket's 24 h lifecycle got there first, or the upload never
            # landed. Nothing to retry.
            return {**base, "status": "failed", "poses": {}, "error_code": "image_missing"}

        result = await asyncio.to_thread(self._measure, images, msg)
        result = {**base, **result}
        result.setdefault("meta", {})
        result["meta"].update(
            pose_model=self._models[0],
            segmentation_model=self._models[1],
            ms=round((time.monotonic() - start) * 1000),
        )
        return result

    def _measure(self, images: dict[str, bytes], msg: dict) -> dict:
        views: dict[str, View] = {}
        verdicts: dict[str, str] = {}
        first_failure: tuple[str, str] | None = None
        for pose in POSES:
            # Table order (capture-qc.md §1-§2): decode and resolution, then
            # lighting and blur judged on the person, then the pose rows.
            pre = image_qc.precheck(images[pose], self._qc)
            code = pre.code
            if code is None:
                detection = self._analyzer.analyze(pre.image)
                quality = image_qc.quality(pre.image, detection.mask, self._qc)
                code = quality.code or pose_qc.check(detection, pose, self._qc)
                if code is None:
                    views[pose] = View(detection, quality.sharpness)
            verdicts[pose] = "failed" if code else "accepted"
            if code and first_failure is None:
                first_failure = (code, pose)

        if first_failure:
            code, pose = first_failure
            return {"status": "failed_qc", "poses": verdicts, "qc": {"code": code, "pose": pose}}

        estimator = Estimator(views["front"], views["side"], float(msg["height_cm"]), self._cal, self._qc)
        measurements = []
        for spec in msg["measures"]:
            name = spec["name"]
            if not estimator.supports(name):
                log.warning("measure has no estimator", extra={"step": "estimate", "measure": name})
                continue
            est = estimator.estimate(name)
            if est is None or est.value_cm <= 0:
                log.warning("measure could not be estimated", extra={"step": "estimate", "measure": name})
                continue
            measurements.append({"name": name, "value_cm": round(est.value_cm, 1), "confidence": estimator.confidence(est)})
        return {
            "status": "measured",
            "poses": verdicts,
            "measurements": measurements,
            "meta": {"height_suspect": estimator.height_suspect()},
        }
