from fastapi import APIRouter, File, Form, HTTPException, Request, UploadFile

from app.config import settings
from app.model.schemas import MeasurementResponse
from app.service.pose import NoBodyDetected

router = APIRouter()


@router.post("/measure", response_model=MeasurementResponse)
async def create_measurement(
    request: Request,
    image: UploadFile = File(...),
    user_height_cm: float = Form(default=settings.default_height_cm),
):
    """Estimate body measurements from an uploaded full-body image."""
    data = await image.read()
    try:
        return request.app.state.measurer.measure(data, user_height_cm)
    except NoBodyDetected:
        raise HTTPException(status_code=422, detail="No body detected in the image")
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc))
