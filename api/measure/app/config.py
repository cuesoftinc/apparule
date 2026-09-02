"""Environment-based configuration for the measure service."""
import os


class Settings:
    def __init__(self) -> None:

        # Pose model
        self.pose_model_path = os.getenv(
            "POSE_MODEL_PATH",
            "pose_landmarker.task",
        )

        # Segmentation model
        self.segmentation_model_path = os.getenv(
            "SEGMENTATION_MODEL_PATH",
            "selfie_segmenter.tflite",
        )

        # Server
        self.port = int(os.getenv("PORT", "8081"))

        # Default user height
        self.default_height_cm = float(
            os.getenv("DEFAULT_USER_HEIGHT_CM", "170")
        )


settings = Settings()
