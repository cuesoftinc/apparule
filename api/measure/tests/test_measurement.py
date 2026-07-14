"""Unit tests for the migrated measurement math (no mediapipe required)."""
from app.service import measurement


class P:
    def __init__(self, x, y):
        self.x = x
        self.y = y


def test_convert_pixels_to_cm():
    assert measurement.convert_pixels_to_cm(10, 2) == 20


def test_shoulder_width_px():
    landmarks = {11: P(0.4, 0.5), 12: P(0.6, 0.5)}
    # horizontal separation of 0.2 * width(100) = 20px
    assert round(measurement.calculate_shoulder_width(landmarks, 100, 100), 2) == 20.0


def test_body_height_px():
    landmarks = {0: P(0.5, 0.1), 27: P(0.5, 0.9), 28: P(0.5, 0.9)}
    # vertical distance nose->ankle = 0.8 * height(100) = 80px
    assert round(measurement.calculate_body_height_pixels(landmarks, 100, 100), 2) == 80.0
