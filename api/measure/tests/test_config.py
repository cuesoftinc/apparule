"""Tests for native-run model path configuration."""

from app.config import Settings


def test_default_model_paths(monkeypatch):
    monkeypatch.delenv("POSE_MODEL_PATH", raising=False)
    monkeypatch.delenv("MODEL_PATH", raising=False)
    monkeypatch.delenv("SEGMENTATION_MODEL_PATH", raising=False)

    settings = Settings()

    assert settings.pose_model_path == "pose_landmarker.task"
    assert settings.segmentation_model_path == "selfie_segmenter.tflite"


def test_legacy_pose_model_path_is_supported(monkeypatch):
    monkeypatch.delenv("POSE_MODEL_PATH", raising=False)
    monkeypatch.setenv("MODEL_PATH", "custom-pose.task")

    assert Settings().pose_model_path == "custom-pose.task"


def test_new_pose_model_path_takes_precedence(monkeypatch):
    monkeypatch.setenv("POSE_MODEL_PATH", "new-pose.task")
    monkeypatch.setenv("MODEL_PATH", "old-pose.task")
    monkeypatch.setenv("SEGMENTATION_MODEL_PATH", "custom-segmenter.tflite")

    settings = Settings()

    assert settings.pose_model_path == "new-pose.task"
    assert settings.segmentation_model_path == "custom-segmenter.tflite"
