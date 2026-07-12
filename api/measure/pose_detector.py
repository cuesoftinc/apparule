
from re import X
import mediapipe as mp
import cv2
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

from measurement_utils import(
    calculate_body_height_pixels,
    calculate_hip_width,
    calculate_shoulder_width,
    convert_pixels_to_cm
  


)

MODEL_PATH = "pose_landmarker.task"
IMAGE_PATH = "test_image1.jpg"
OUTPUT_PATH = "output_landmarks.jpg"

USER_HEIGHT_CM = 170



def draw_landmark(cv_image,landmark,image_width,image_height):
    x = int(landmark.x * image_width)
    y = int(landmark.y * image_height)
    cv2.circle(cv_image,(x,y),5,(0,255,0),-1)

def draw_line(cv_image,point1,point2,image_width,image_height,color):
    x1 = int(point1.x * image_width)
    y1 = int(point1.y * image_height)
    x2 = int(point2.x * image_width)
    y2 = int(point2.y * image_height)


    cv2.line(cv_image,(x1,y1),(x2,y2),color, 3)


#load model
base_options = python.BaseOptions(model_asset_path=MODEL_PATH)

#detector settings
options = vision.PoseLandmarkerOptions(
    base_options = base_options,
    running_mode = vision.RunningMode.IMAGE,
    num_poses=1 #one person per detection
)

#detector
detector = vision.PoseLandmarker.create_from_options(options)



try:
#load image in mediapipe format
    image = mp.Image.create_from_file(IMAGE_PATH)

#inference
    result = detector.detect(image)

    if not result.pose_landmarks:
        print("No body detected")
        exit()
    #extract landmark from body
    landmarks = result.pose_landmarks[0]

    #load image with opencv 
    cv_image= cv2.imread(IMAGE_PATH)

    if cv_image is None:
        print("Could not load image with openCV")
        exit()

    image_height, image_width, _ = cv_image.shape

    shoulder_width_px = calculate_shoulder_width(landmarks,image_width,image_height)
    hip_width_px = calculate_hip_width(landmarks,image_width,image_height)
    body_height_px = calculate_body_height_pixels(landmarks,image_width,image_height)

    scale_factor = USER_HEIGHT_CM/body_height_px

    shoulder_width_cm = convert_pixels_to_cm(shoulder_width_px,scale_factor)
    hip_width_cm = convert_pixels_to_cm(hip_width_px,scale_factor)

    print("Body height in pixels:", body_height_px)
    print("Scale factor:", scale_factor)
    print("Shoulder width in pixels:",shoulder_width_px)
    print("Hip width in pixels:",hip_width_px)
    print("Estimated shoulder width:",round(shoulder_width_cm,2),"cm")
    print("Estimated hip width:", round(hip_width_cm,2),"cm")


    #draw landmarks
    for landmark in landmarks:
        draw_landmark(cv_image,landmark,image_width,image_height)

    draw_line(cv_image,landmarks[11], landmarks[12],image_width,image_height,(255,0,0))
    draw_line(cv_image,landmarks[23], landmarks[24],image_width,image_height,(0,0,255))

    nose = landmarks[0]

    left_ankle = landmarks[27]
    right_ankle = landmarks[28]

    class MidPoint:
        def __init__(self,x,y):
            self.x = x
            self.y = y
    ankle_mid = MidPoint(
        (left_ankle.x + right_ankle.x) /2,
        (left_ankle.y+right_ankle.y)/2
    )

    draw_line(cv_image,nose,ankle_mid,image_width,image_height,(0,255,255))


    cv2.imwrite(OUTPUT_PATH,cv_image)

    print(f"Landmark image saved as {OUTPUT_PATH}")

finally:
    detector.close()