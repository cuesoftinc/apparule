"""Tests for native-run model path configuration."""

from app.config import QC, Settings


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


def test_kafka_brokers_split(monkeypatch):
    monkeypatch.setenv("KAFKA_BROKERS", "a:9092, b:9092,")
    assert Settings().kafka_broker_list == ["a:9092", "b:9092"]


def test_thresholds_match_capture_qc():
    """capture-qc.md §1-§2: the defaults are decided, not tuned here."""
    assert (QC.min_short_edge_px, QC.min_luma, QC.max_luma, QC.min_laplacian_var) == (480, 40, 215, 60)
    assert (QC.frontal_ratio_min, QC.frontal_ratio_max, QC.shoulder_z_delta) == (0.9, 2.2, 0.15)
    assert (QC.max_tilt_degrees, QC.arms_clearance, QC.min_body_height_fraction) == (15, 0.05, 0.4)
