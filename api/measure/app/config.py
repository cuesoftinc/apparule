"""Environment-based configuration for the measure service."""
import os


class Settings:
    def __init__(self) -> None:
        self.model_path = os.getenv("MODEL_PATH", "pose_landmarker.task")
        self.port = int(os.getenv("PORT", "8081"))
        self.default_height_cm = float(os.getenv("DEFAULT_USER_HEIGHT_CM", "170"))


settings = Settings()
