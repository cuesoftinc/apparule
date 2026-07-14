"""Pose detection + body measurement (migrated from pose_detector.py).

The debug landmark-drawing / output-image code from the original script is
intentionally omitted — this is a service, not a visualization tool.
"""
import cv2
import mediapipe as mp
import numpy as np
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

from app.service import measurement


class NoBodyDetected(Exception):
    """Raised when no pose landmarks are found in the image."""


class PoseMeasurer:
    """Loads the pose model once and measures bodies from image bytes."""

    def __init__(self, model_path: str) -> None:
        base_options = python.BaseOptions(model_asset_path=model_path)
        options = vision.PoseLandmarkerOptions(
            base_options=base_options,
            running_mode=vision.RunningMode.IMAGE,
            num_poses=1,  # one person per detection
        )
        self._detector = vision.PoseLandmarker.create_from_options(options)

    def measure(self, image_bytes: bytes, user_height_cm: float) -> dict:
        arr = np.frombuffer(image_bytes, dtype=np.uint8)
        cv_image = cv2.imdecode(arr, cv2.IMREAD_COLOR)
        if cv_image is None:
            raise ValueError("Could not decode the uploaded image")
        image_height, image_width, _ = cv_image.shape

        rgb = cv2.cvtColor(cv_image, cv2.COLOR_BGR2RGB)
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)

        result = self._detector.detect(mp_image)
        if not result.pose_landmarks:
            raise NoBodyDetected("No body detected")
        landmarks = result.pose_landmarks[0]

        shoulder_px = measurement.calculate_shoulder_width(landmarks, image_width, image_height)
        hip_px = measurement.calculate_hip_width(landmarks, image_width, image_height)
        body_height_px = measurement.calculate_body_height_pixels(landmarks, image_width, image_height)
        if body_height_px <= 0:
            raise ValueError("Unable to estimate body height from the image")

        scale_factor = user_height_cm / body_height_px
        return {
            "body_height_px": body_height_px,
            "scale_factor": scale_factor,
            "shoulder_width_px": shoulder_px,
            "shoulder_width_cm": round(measurement.convert_pixels_to_cm(shoulder_px, scale_factor), 2),
            "hip_width_px": hip_px,
            "hip_width_cm": round(measurement.convert_pixels_to_cm(hip_px, scale_factor), 2),
        }

    def close(self) -> None:
        self._detector.close()
