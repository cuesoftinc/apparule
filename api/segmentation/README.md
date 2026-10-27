# Apparule segmentation (`api/segmentation`)

Pose QC and body measurements (Python, port 8081; docs/system-design.md §4,
§6.1). Formerly `api/measure`. No public ingress: HTTP serves only `/health`
and `/ready`, and the work arrives over Kafka.

1. Consume `apparule.capture.ready` from the shared bus's `cuelabs.requests`
   lane (consumer group `apparule-segmentation`). It points at both pose
   images in `tmp/` and carries the height and the customer's A-10 template.
2. Run the image pre-checks and pose QC on **each** pose
   (docs/capture-qc.md §1-§2; first failure in table order per pose).
3. If both poses pass, estimate every measure of the template with the
   `mediapipe_2d_v2` method and score each one (§3-§4).
4. Publish `apparule.capture.measured` on `cuelabs.results`, by pointer:
   `measured` with the values, `failed_qc` with `{code, pose}` and which
   poses were accepted, or `failed` when an image is gone.

It keeps no state: no database, no Redis.

## The method (`mediapipe_2d_v2`)

- MediaPipe's pose landmarker (`pose_landmarker.task`, probing for two
  people) and selfie segmenter (`selfie_segmenter.tflite`) run on each view.
- **Scale:** each view's nose-to-ankle height is 93% of the stated height.
- **Lengths** (sleeve, shin, trouser, gown, the shoulder drops) come from the
  front view's landmarks.
- **Girths** (bust/chest, under-bust, waist, hip, neck, thigh, knee) combine
  the front view's width with the side view's depth at the same body row, both
  read from the segmentation mask, as an ellipse.
- **Confidence** is capture-qc.md §4's formula across both views.

The rows and factors are in `app/config.py :: Calibration`. They are
uncalibrated defaults until the two-view benchmark against tape measurements
(capture-qc.md §3, the recalibration directive); the QC thresholds are in
`QCThresholds`, versioned as `thresholds_version`.

## Layout

```
app/main.py           FastAPI + lifespan: models, consumer, producer
app/config.py         env config, QC thresholds, calibration
pipeline.py           capture.ready -> capture.measured
qc/                   image pre-checks, pose QC
pose/                 pose landmarker + segmenter wrappers
measurement/          landmark geometry, the two-view estimator
kafka/ storage/ contract/ health/ telemetry/   shared service plumbing
demo_pose.py demo_segment.py                     local model demos
tests/                pytest suite (synthetic people; no model needed)
```

## Run

From the repo root (recommended): `make up`. Natively:

```bash
cp .env.example .env
pip install -r requirements-dev.txt
uvicorn app.main:app --port 8081
```

## Test

```bash
pytest && ruff check .
```
