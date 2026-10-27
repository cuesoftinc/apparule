"""Pose detection + segmentation for one image (migrated from pose_detector.py).

The debug landmark-drawing / output-image code from the original script is
intentionally omitted — this is a service, not a visualization tool.
"""

from dataclasses import dataclass

import cv2
import mediapipe as mp
import numpy as np
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

from pose.segmenter import BodySegmenter


@dataclass
class Landmark:
    x: float
    y: float
    z: float
    visibility: float


@dataclass
class Detection:
    """What the models found in one decoded image."""

    width: int
    height: int
    # Number of people the detector found (it probes for two, capture-qc.md §2).
    people: int
    # The first person's 33 landmarks, normalized to the image; empty when
    # nobody was found.
    landmarks: list[Landmark]
    # True where the person is; None when nobody was found.
    mask: np.ndarray | None


class PoseAnalyzer:
    """Loads the pose and segmentation models once and runs both on an image."""

    def __init__(self, pose_model_path: str, segmentation_model_path: str) -> None:
        base_options = python.BaseOptions(model_asset_path=pose_model_path)
        options = vision.PoseLandmarkerOptions(
            base_options=base_options,
            running_mode=vision.RunningMode.IMAGE,
            num_poses=2,  # the single-subject check needs to see a second person
        )
        self._detector = vision.PoseLandmarker.create_from_options(options)
        self._segmenter = BodySegmenter(segmentation_model_path)

    def analyze(self, bgr: np.ndarray) -> Detection:
        height, width, _ = bgr.shape
        rgb = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)

        result = self._detector.detect(mp_image)
        people = len(result.pose_landmarks)
        if not people:
            return Detection(width, height, 0, [], None)
        landmarks = [
            Landmark(p.x, p.y, p.z, p.visibility if p.visibility is not None else 0.0)
            for p in result.pose_landmarks[0]
        ]
        return Detection(width, height, people, landmarks, self._segmenter.person_mask(mp_image))

    def close(self) -> None:
        self._detector.close()
        self._segmenter.close()
