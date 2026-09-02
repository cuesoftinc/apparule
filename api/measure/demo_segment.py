import cv2
import mediapipe as mp
import numpy as np
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

# -----------------------------
# Configuration
# -----------------------------
MODEL_PATH = "selfie_segmenter.tflite"
IMAGE_PATH = "demo/input/image_test2.jpeg"
MASK_OUTPUT = "demo/output/segmentation_mask.png"
OVERLAY_OUTPUT = "demo/output/segmentation_overlay.png"


# Load model

base_options = python.BaseOptions(
    model_asset_path=MODEL_PATH
)

options = vision.ImageSegmenterOptions(
    base_options=base_options,
    running_mode=vision.RunningMode.IMAGE,
    output_category_mask=True,
)

segmenter = vision.ImageSegmenter.create_from_options(options)


# Read image

image = cv2.imread(IMAGE_PATH)

if image is None:
    raise FileNotFoundError(f"Could not load image: {IMAGE_PATH}")

rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

mp_image = mp.Image(
    image_format=mp.ImageFormat.SRGB,
    data=rgb,
)


# Run segmentation

result = segmenter.segment(mp_image)

mask = result.category_mask.numpy_view()
mask = cv2.bitwise_not(mask)

print("Min:", mask.min())
print("Max:", mask.max())
print("Type:", mask.dtype)


cv2.imwrite(MASK_OUTPUT, mask)

mask_rgb = cv2.cvtColor(mask, cv2.COLOR_GRAY2BGR)

# Green image
green = np.zeros_like(image)
green[:] = (0, 255, 0)

# Keep green only where the mask is white
person_green = cv2.bitwise_and(green, mask_rgb)

# Blend with original image
overlay = cv2.addWeighted(
    image,
    0.7,
    person_green,
    0.3,
    0
)

# Save overlay
cv2.imwrite(OVERLAY_OUTPUT, overlay)

print(f"Saved mask to: {MASK_OUTPUT}")
print(f"Saved overlay to: {OVERLAY_OUTPUT}")

segmenter.close()