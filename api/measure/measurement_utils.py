import math



#mediapipe landmark index - from documentation
# 0 - nose
# 1 - left eye (inner)
# 2 - left eye
# 3 - left eye (outer)
# 4 - right eye (inner)
# 5 - right eye
# 6 - right eye (outer)
# 7 - left ear
# 8 - right ear
# 9 - mouth (left)
# 10 - mouth (right)
# 11 - left shoulder
# 12 - right shoulder
# 13 - left elbow
# 14 - right elbow
# 15 - left wrist
# 16 - right wrist
# 17 - left pinky
# 18 - right pinky
# 19 - left index
# 20 - right index
# 21 - left thumb
# 22 - right thumb
# 23 - left hip
# 24 - right hip
# 25 - left knee
# 26 - right knee
# 27 - left ankle
# 28 - right ankle
# 29 - left heel
# 30 - right heel
# 31 - left foot index
# 32 - right foot index
NOSE = 0

LEFT_SHOULDER = 11
RIGHT_SHOULDER = 12

LEFT_HIP = 23
RIGHT_HIP = 24

LEFT_ANKLE = 27
RIGHT_ANKLE = 28

# def normalized_distance(p1,p2):
#     return math.sqrt((p1.x - p2.x) ** 2 +(p1.y - p2.y)**2)

def pixel_distance(p1,p2,image_width,image_height):
    x1 = p1.x * image_width
    y1 = p1.y * image_height
    x2 = p2.x * image_width
    y2 = p2.y * image_height

    return math.sqrt((x2-x1)**2 + (y2-y1)**2)

def calculate_shoulder_width(landmarks,image_width,image_height):
    return pixel_distance(
        landmarks[LEFT_SHOULDER],
        landmarks[RIGHT_SHOULDER],
        image_width,
        image_height
    )

def calculate_hip_width(landmarks,image_width,image_height):
    return pixel_distance(
        landmarks[LEFT_HIP],
        landmarks[RIGHT_HIP],
        image_width,
        image_height
    )


def calculate_body_height_pixels(landmarks,image_width,image_height):
    nose = landmarks[NOSE]
    left_ankle = landmarks[LEFT_ANKLE]
    right_ankle = landmarks[RIGHT_ANKLE]

    nose_x = nose.x * image_width
    nose_y = nose.y * image_height

    ankle_mid_x= ((left_ankle.x + right_ankle.x)/2)* image_width
    ankle_y = max(left_ankle.y,right_ankle.y) * image_height

    return math.sqrt((ankle_mid_x - nose_x)** 2 + (ankle_y - nose_y)**2)

def convert_pixels_to_cm(pixel_measurement, scale_factor):
    return pixel_measurement * scale_factor