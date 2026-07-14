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

## Test

```bash
pip install -r requirements-dev.txt && pytest
```
