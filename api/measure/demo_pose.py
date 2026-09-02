import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

base_options = python.BaseOptions(
    model_asset_path="pose_landmarker.task"
)

options = vision.PoseLandmarkerOptions(
    base_options=base_options,
    running_mode=vision.RunningMode.IMAGE,
)

detector = vision.PoseLandmarker.create_from_options(options)

image = cv2.imread("demo/input/image_test2.jpeg")

rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

mp_image = mp.Image(
    image_format=mp.ImageFormat.SRGB,
    data=rgb
)

result = detector.detect(mp_image)

# Check if a pose was detected
if not result.pose_landmarks:
    print("No pose detected.")
    detector.close()
    exit()

# Get image dimensions
height, width, _ = image.shape

# Draw each landmark
for landmark in result.pose_landmarks[0]:
    x = int(landmark.x * width)
    y = int(landmark.y * height)

    cv2.circle(
        image,
        (x, y),
        6,              # radius
        (0, 255, 0),    # green
        -1              # filled circle
    )

# Save the image
output_path = "demo/output/pose_landmarks.jpg"

cv2.imwrite(output_path, image)

print(f"Pose image saved to: {output_path}")

detector.close()