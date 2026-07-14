from pydantic import BaseModel


class MeasurementResponse(BaseModel):
    body_height_px: float
    scale_factor: float
    shoulder_width_px: float
    shoulder_width_cm: float
    hip_width_px: float
    hip_width_cm: float
