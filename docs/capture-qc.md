# Apparule, Capture QC & Measurement Confidence Contract

> The numeric thresholds behind flows/vault.md's QC gate and the confidence
> value stored per measurement (data-model.md `MEASUREMENT.confidence`).
> Grounded in the current MediaPipe pipeline (33 pose landmarks, each with a
> `visibility` score 0–1). Thresholds are **[Decided defaults]**, tuneable
> constants in one config block, revisited against the accuracy benchmark
> (roadmap Phase 5 harness), never scattered magic numbers.
> A capture is **two photos**, front + side (right profile), plus height
> (M-10, decisions.md); QC runs and reports **per pose**.

## 1. Image checks

Run **per image**, each pose's photo passes the same table. Brightness
and blur are judged **on the person** (the segmentation mask and its
bounding box), not the whole frame: a person against a bright white wall
is well lit, and a plain wall is not a blurry photo **[Revised 2026-10-21:
the whole-frame rules failed well-lit, sharp photos taken against white
walls]**. When no person is segmented, the whole frame is used.

| Check | Threshold | Fail code |
| --- | --- | --- |
| Decodable | cv2 decode succeeds | `undecodable_image` |
| Resolution | short edge ≥ 480px | `low_resolution` (new code) |
| Brightness | mean luma of the person's pixels in [40, 215] | `poor_lighting` (new code) |
| Blur | Laplacian variance over the person's bounding box ≥ 60 | `blurry` (new code) |

## 2. Pose QC (after detection)

Let `vis(i)` = landmark i visibility. Key sets: HEAD = {nose}, SHOULDERS =
{11,12}, HIPS = {23,24}, ANKLES = {27,28}.

### Pose 1, front

| Check | Rule | Fail code |
| --- | --- | --- |
| Body present | detector returns ≥1 pose | `no_body` |
| Single subject | exactly 1 pose (`num_poses=2` probe run; if 2 detected → fail) | `multiple_bodies` |
| Full body | min vis over HEAD∪SHOULDERS∪HIPS∪ANKLES ≥ 0.5 | `partial_body` |
| In-frame margins | all key landmarks within [2%, 98%] of both axes | `partial_body` |
| Frontality | shoulder-width\_px ÷ hip-width\_px ∈ [0.9, 2.2] AND both shoulders' z within 0.15 of each other AND shoulder span ÷ torso length ≥ 0.4 | `not_frontal` (new code) |
| Upright | angle of nose→ankle-midpoint axis within 15° of vertical | `camera_tilt` (new code) |
| Arms clearance | wrist landmarks ≥ 5% image-width away from hip landmarks horizontally (arms slightly out, not fused to torso) | `arms_position` (new code) |
| Scale sanity | body_height_px ≥ 40% of image height | `too_far` (new code) |

### Pose 2, side (profile) deltas

**[Revised 2026-10-21]** In a true profile the far shoulder, hip, wrist
and ankle are hidden behind the body, and the pose model only guesses where
they are, so the side pose judges **the side facing the camera**: the
side the model sees more clearly (higher visibility of shoulder + hip +
ankle), and on a tie the one with the nearer shoulder (smaller z). The
earlier rules applied the front's both-sides visibility test and a
shoulder ÷ hip width ratio < 0.9; a correct profile photo fails both (far
ankle visibility 0.17; ratio 1.48, because shoulder and hip widths shrink
together in profile). Either profile is accepted, left or right side to
the camera, since measuring doesn't depend on which; the app's guide and
copy still ask for the right side.

| Check | Rule | Fail code |
| --- | --- | --- |
| Body present, single subject | as the front pose | `no_body`, `multiple_bodies` |
| Full body | min vis over HEAD ∪ the camera-side shoulder, hip and ankle ≥ 0.5 | `partial_body` |
| In-frame margins | those landmarks within [2%, 98%] of both axes | `partial_body` |
| Profile orientation | shoulder span ÷ torso length < 0.4 (≈ 0.1 in profile, ≈ 0.5 facing the camera) | `not_side_profile` (new code) |
| Upright | angle of the nose → camera-side-ankle axis within 15° of vertical | `camera_tilt` |
| Arms relaxed | the camera-side wrist within 5% image-width of its hip horizontally (arm hanging at the side) | `arms_position` (side-pose guidance copy) |
| Scale sanity | nose → camera-side ankle ≥ 40% of image height | `too_far` |

Each code carries guidance copy (flows/vault.md table extends with the new
codes; `arms_position` copy is per pose). Multiple failures report the
**first by the table order above**, one actionable instruction beats a
list, and reporting is **per pose**: the error names the failing pose,
and an accepted pose is never discarded by the other pose's failure
(flows/vault.md §1, the client re-enters the failing pose's camera only).

## 3. Height-scale plausibility

`scale = user_height_cm / body_height_px` uses the nose→ankle-midpoint
distance, which is ~93% of true stature (nose≠crown, ankle≠sole). Corrected:
`scale = (user_height_cm × 0.93) / body_height_px` **[Decided: ships as
`method: mediapipe_2d_v2`, the correction shifts all outputs ~7%, so it is a
new method identifier, never a silent change to v1 sessions]**. Plausibility band: if the
implied crown-to-sole pixel height maps outside 0.75–1.33× of the claimed
height when cross-checked against torso proportions (shoulder-to-hip ÷
stature expected ≈ 0.25±0.08), flag `pipeline_meta.qc.height_suspect = true`
(session still saves; UI shows "double-check your height" hint).

**Side-pose contribution (M-10)**: girth measures estimate from the two
views, front width + side depth per landmark pair, combined via an
elliptical-circumference approximation; the front image alone keeps owning
the height scale (the nose→ankle axis is most stable in the frontal view).
The v2 constants (the 0.93 stature correction, the plausibility band, and
the ellipse-eccentricity defaults for two-view girths) must be
re-benchmarked for the two-view method, **[Specified: measurement
pipeline recalibration needed, backend phase]**.

## 4. Per-measurement confidence (2-D method)

```
confidence(m) = clamp01( mean_vis(m) × frontality_factor × sharpness_factor )
  mean_vis(m)        = mean visibility of the landmarks defining m
  frontality_factor  = 1.0 if shoulder/hip ratio in [1.2, 1.9]; else 0.85
  sharpness_factor   = 1.0 if Laplacian var ≥ 120; 0.9 if ≥ 60
```

Stored per `MEASUREMENT` row; UI renders <0.7 with a "low confidence, consider retaking" chip. Two-view girths (M-10) span both images:
`mean_vis(m)` covers the landmarks of both contributing views, and the
orientation factor applies per view (frontality on the front image, profile
orientation on the side), exact factors settle with the recalibration
(§3). Manual entries have `confidence = null` (human
truth isn't scored). SMPL-era confidences (Phase 5) replace this formula
per-method, the field is method-agnostic by design.

## 5. Config block (single source)

The thresholds version is `qc-2026-10-21` (it was `qc-2026-10-19` before the side-pose and on-the-person revisions). All constants above live in `api/segmentation/app/config.py :: QCThresholds` (one dataclass; the v2 calibration constants beside it in `Calibration`),
logged (as config, not per-image) at service start, echoed into
`pipeline_meta.qc.thresholds_version` per session so historical sessions
remain interpretable after tuning.

## 6. Acceptance

- [ ] Golden image set: ≥1 fixture per fail code + 5 passing fixtures per
      pose; CI-run
- [ ] Threshold changes bump `thresholds_version`; old sessions untouched
- [ ] First-failure-only reporting verified per pose (multi-fault fixture);
      a pose-2 failure leaves the accepted pose-1 image undisturbed
- [ ] Confidence values populate and render; manual rows null
- [ ] Height correction ships behind `pipeline_meta.method` rev with the
      benchmark harness comparing before/after against tape measurements
- [ ] `height_suspect` hint ("double-check your height", §3), **deferred
      [Decided 2026-07-22]**: implemented by neither client; it ships
      with the backend phase's pipeline work, not before
