# Apparule — Capture QC & Measurement Confidence Contract

> The numeric thresholds behind flows/vault.md's QC gate and the confidence
> value stored per measurement (data-model.md `MEASUREMENT.confidence`).
> Grounded in the current MediaPipe pipeline (33 pose landmarks, each with a
> `visibility` score 0–1). Thresholds are **[Decided defaults]** — tuneable
> constants in one config block, revisited against the accuracy benchmark
> (roadmap Phase 5 harness), never scattered magic numbers.

## 1. Image pre-checks (before pose detection)

| Check | Threshold | Fail code |
| --- | --- | --- |
| Decodable | cv2 decode succeeds | `undecodable_image` |
| Resolution | short edge ≥ 480px | `low_resolution` (new code) |
| Brightness | mean luma in [40, 215] | `poor_lighting` (new code) |
| Blur | Laplacian variance ≥ 60 | `blurry` (new code) |

## 2. Pose QC (after detection)

Let `vis(i)` = landmark i visibility. Key sets: HEAD = {nose}, SHOULDERS =
{11,12}, HIPS = {23,24}, ANKLES = {27,28}.

| Check | Rule | Fail code |
| --- | --- | --- |
| Body present | detector returns ≥1 pose | `no_body` |
| Single subject | exactly 1 pose (`num_poses=2` probe run; if 2 detected → fail) | `multiple_bodies` |
| Full body | min vis over HEAD∪SHOULDERS∪HIPS∪ANKLES ≥ 0.5 | `partial_body` |
| In-frame margins | all key landmarks within [2%, 98%] of both axes | `partial_body` |
| Frontality | shoulder-width\_px ÷ hip-width\_px ∈ [0.9, 2.2] AND both shoulders' z within 0.15 of each other | `not_frontal` (new code) |
| Upright | angle of nose→ankle-midpoint axis within 15° of vertical | `camera_tilt` (new code) |
| Arms clearance | wrist landmarks ≥ 5% image-width away from hip landmarks horizontally (arms slightly out, not fused to torso) | `arms_position` (new code) |
| Scale sanity | body_height_px ≥ 40% of image height | `too_far` (new code) |

Each code carries guidance copy (flows/vault.md table extends with the new
codes). Multiple failures report the **first by the table order above** —
one actionable instruction beats a list.

## 3. Height-scale plausibility

`scale = user_height_cm / body_height_px` uses the nose→ankle-midpoint
distance, which is ~93% of true stature (nose≠crown, ankle≠sole). Corrected:
`scale = (user_height_cm × 0.93) / body_height_px` **[Decided: ships as
`method: mediapipe_2d_v2` — the correction shifts all outputs ~7%, so it is a
new method identifier, never a silent change to v1 sessions]**. Plausibility band: if the
implied crown-to-sole pixel height maps outside 0.75–1.33× of the claimed
height when cross-checked against torso proportions (shoulder-to-hip ÷
stature expected ≈ 0.25±0.08), flag `pipeline_meta.qc.height_suspect = true`
(session still saves; UI shows "double-check your height" hint).

## 4. Per-measurement confidence (2-D method)

```
confidence(m) = clamp01( mean_vis(m) × frontality_factor × sharpness_factor )
  mean_vis(m)        = mean visibility of the landmarks defining m
  frontality_factor  = 1.0 if shoulder/hip ratio in [1.2, 1.9]; else 0.85
  sharpness_factor   = 1.0 if Laplacian var ≥ 120; 0.9 if ≥ 60
```

Stored per `MEASUREMENT` row; UI renders <0.7 with a "low confidence —
consider retaking" chip. Manual entries have `confidence = null` (human
truth isn't scored). SMPL-era confidences (Phase 5) replace this formula
per-method — the field is method-agnostic by design.

## 5. Config block (single source)

All constants above live in `app/config.py :: QCThresholds` (one dataclass),
logged (as config, not per-image) at service start, echoed into
`pipeline_meta.qc.thresholds_version` per session so historical sessions
remain interpretable after tuning.

## 6. Acceptance

- [ ] Golden image set: ≥1 fixture per fail code + 5 passing fixtures; CI-run
- [ ] Threshold changes bump `thresholds_version`; old sessions untouched
- [ ] First-failure-only reporting verified (multi-fault fixture)
- [ ] Confidence values populate and render; manual rows null
- [ ] Height correction ships behind `pipeline_meta.method` rev with the
      benchmark harness comparing before/after against tape measurements
