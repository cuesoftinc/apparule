# Apparule Measure (`api/measure`)

Python FastAPI service that derives body measurements from a photo using a
MediaPipe pose model. `/health` + `/ready` on :8081; `POST /measure` accepts
an image and returns measurements.

## Layout

```
app/main.py           FastAPI + lifespan (loads the pose model once)
app/config.py         env config           app/router/   HTTP routes
app/service/          pose + measurement logic
app/model/            pydantic schemas     tests/        pytest suite
pose_landmarker.task  MediaPipe model asset
```

## Run

From the repo root (recommended): `make up` → :8081.
Natively: `pip install -r requirements.txt && uvicorn app.main:app --port 8081`.

For a native run, copy `.env.example` into your environment. `POSE_MODEL_PATH`
and `SEGMENTATION_MODEL_PATH` select the model assets. `MODEL_PATH` is still
accepted as a fallback for existing pose-model configurations.

Knee width is not currently returned by `/measure`. Measuring the distance
between the left and right knee landmarks describes stance, not the width of
one knee; that measurement requires a segmentation boundary.

## Test

```bash
pip install -r requirements-dev.txt && pytest
```
