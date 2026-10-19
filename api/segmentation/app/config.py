"""Typed environment config (CueLABS standard: fail fast on missing settings).

Variable names follow system-design.md §10.3. Nothing else in the service
reads os.environ. The QC and measurement constants live here too, in one
block each (capture-qc.md §5).
"""

from dataclasses import dataclass
from functools import lru_cache
from typing import Literal

from pydantic import AliasChoices, Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore", populate_by_name=True)

    port: int = 8081
    log_level: str = "INFO"

    # Model assets. MODEL_PATH is still read as a fallback for the pose model.
    pose_model_path: str = Field(
        default="pose_landmarker.task",
        validation_alias=AliasChoices("POSE_MODEL_PATH", "MODEL_PATH"),
    )
    segmentation_model_path: str = Field(
        default="selfie_segmenter.tflite",
        validation_alias=AliasChoices("SEGMENTATION_MODEL_PATH"),
    )

    kafka_brokers: str = Field(min_length=1)
    kafka_username: str = ""
    kafka_password: str = ""
    kafka_ssl_ca: str = ""
    kafka_group: str = "apparule-segmentation"

    # api/common's base URL, woken after each result sent for it (scale to
    # zero, shared-messaging.md). Empty where common always runs.
    wake_common_url: str = ""

    # Object storage. gcs in cloud (ADC); s3 for MinIO in compose/self-host.
    storage_driver: Literal["gcs", "s3"] = "gcs"
    storage_bucket: str = Field(min_length=1)
    storage_prefix: str = Field(min_length=1, description="e.g. apparule/stg")
    storage_endpoint: str = ""
    storage_access_key: str = ""
    storage_secret_key: str = ""
    storage_use_ssl: bool = True

    # JSON Schemas copied from api/common/contract at build time.
    contract_dir: str = "contract"

    @property
    def kafka_broker_list(self) -> list[str]:
        return [b.strip() for b in self.kafka_brokers.split(",") if b.strip()]


@dataclass(frozen=True)
class QCThresholds:
    """capture-qc.md §1-§2. Changing any value bumps `version`, which every
    result echoes as `thresholds_version` so old sessions stay interpretable."""

    version: str = "qc-2026-10-19"
    # §1 image pre-checks
    min_short_edge_px: int = 480
    min_luma: float = 40.0
    max_luma: float = 215.0
    min_laplacian_var: float = 60.0
    # §2 pose QC
    min_key_visibility: float = 0.5
    margin: float = 0.02
    frontal_ratio_min: float = 0.9
    frontal_ratio_max: float = 2.2
    shoulder_z_delta: float = 0.15
    max_tilt_degrees: float = 15.0
    arms_clearance: float = 0.05
    min_body_height_fraction: float = 0.4
    # §4 confidence
    confident_ratio_min: float = 1.2
    confident_ratio_max: float = 1.9
    sharp_laplacian_var: float = 120.0


@dataclass(frozen=True)
class Calibration:
    """mediapipe_2d_v2 constants (capture-qc.md §3). Uncalibrated defaults:
    the two-view method still owes its re-benchmark against tape measurements
    (the recalibration directive), so these are tuning knobs, not findings."""

    # Nose-to-ankle is ~93% of stature.
    stature_correction: float = 0.93
    # Height-plausibility band for shoulder-to-hip over stature.
    torso_ratio_min: float = 0.17
    torso_ratio_max: float = 0.33
    # Body rows as fractions of the shoulder-to-hip span, measured down from
    # the shoulder line (negative = above it, beyond 1 = below the hips).
    neck_row: float = -0.12
    bust_row: float = 0.35
    under_bust_row: float = 0.5
    waist_row: float = 0.75
    hip_row: float = 1.1
    top_length_row: float = 1.35
    # Fraction of the hip-to-knee span below the hips for the thigh girth.
    thigh_row: float = 0.25
    # Bust points sit this fraction of the front chest width apart.
    bust_span_fraction: float = 0.45


QC = QCThresholds()
CALIBRATION = Calibration()


@lru_cache
def get_settings() -> Settings:
    return Settings()  # type: ignore[call-arg]  # values come from the environment
