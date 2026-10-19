"""§1 image pre-checks, run on each pose's photo before pose detection."""

from dataclasses import dataclass

import cv2
import numpy as np

from app.config import QCThresholds


@dataclass
class ImageCheck:
    image: np.ndarray | None
    # Laplacian variance, kept for the confidence formula's sharpness factor.
    sharpness: float
    code: str | None


def decode(data: bytes) -> np.ndarray | None:
    arr = np.frombuffer(data, dtype=np.uint8)
    return cv2.imdecode(arr, cv2.IMREAD_COLOR)


def precheck(data: bytes, qc: QCThresholds) -> ImageCheck:
    image = decode(data)
    if image is None:
        return ImageCheck(None, 0.0, "undecodable_image")
    height, width = image.shape[:2]
    if min(height, width) < qc.min_short_edge_px:
        return ImageCheck(image, 0.0, "low_resolution")
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    luma = float(gray.mean())
    if not qc.min_luma <= luma <= qc.max_luma:
        return ImageCheck(image, 0.0, "poor_lighting")
    sharpness = float(cv2.Laplacian(gray, cv2.CV_64F).var())
    if sharpness < qc.min_laplacian_var:
        return ImageCheck(image, sharpness, "blurry")
    return ImageCheck(image, sharpness, None)
