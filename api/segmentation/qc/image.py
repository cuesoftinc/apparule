"""§1 image checks. Decoding and resolution run before pose detection;
lighting and blur are judged on the person, not the whole frame, once the
segmentation mask exists: a person against a bright white wall is well lit,
and a plain wall is not a blurry photo."""

from dataclasses import dataclass

import cv2
import numpy as np

from app.config import QCThresholds


@dataclass
class ImageCheck:
    image: np.ndarray | None
    code: str | None


@dataclass
class Quality:
    # Laplacian variance of the person's region, kept for the confidence
    # formula's sharpness factor.
    sharpness: float
    luma: float
    code: str | None


def decode(data: bytes) -> np.ndarray | None:
    arr = np.frombuffer(data, dtype=np.uint8)
    return cv2.imdecode(arr, cv2.IMREAD_COLOR)


def precheck(data: bytes, qc: QCThresholds) -> ImageCheck:
    image = decode(data)
    if image is None:
        return ImageCheck(None, "undecodable_image")
    height, width = image.shape[:2]
    if min(height, width) < qc.min_short_edge_px:
        return ImageCheck(image, "low_resolution")
    return ImageCheck(image, None)


def person_region(gray: np.ndarray, mask: np.ndarray | None) -> tuple[np.ndarray, np.ndarray | None]:
    """The person's bounding box (and the mask within it), or the whole frame
    when no person was segmented."""
    if mask is None or not mask.any():
        return gray, None
    rows = np.flatnonzero(mask.any(axis=1))
    cols = np.flatnonzero(mask.any(axis=0))
    box = (slice(rows[0], rows[-1] + 1), slice(cols[0], cols[-1] + 1))
    return gray[box], mask[box]


def quality(image: np.ndarray, mask: np.ndarray | None, qc: QCThresholds) -> Quality:
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    region, region_mask = person_region(gray, mask)
    # Brightness of the person's own pixels; sharpness over their box, where
    # the body's edges and clothing texture are.
    luma = float(region[region_mask].mean()) if region_mask is not None else float(region.mean())
    sharpness = float(cv2.Laplacian(region, cv2.CV_64F).var())
    if not qc.min_luma <= luma <= qc.max_luma:
        return Quality(sharpness, luma, "poor_lighting")
    if sharpness < qc.min_laplacian_var:
        return Quality(sharpness, luma, "blurry")
    return Quality(sharpness, luma, None)
