"""Body-measurement math (migrated from measurement_utils.py).

MediaPipe pose landmark indices (subset used here):
  0 nose · 11/12 left/right shoulder · 23/24 left/right hip · 27/28 left/right ankle
"""
import math


NOSE = 0
LEFT_SHOULDER = 11
RIGHT_SHOULDER = 12
LEFT_HIP = 23
RIGHT_HIP = 24
LEFT_ANKLE = 27
RIGHT_ANKLE = 28
LEFT_ELBOW = 13
RIGHT_ELBOW = 14
LEFT_WRIST = 15
RIGHT_WRIST = 16
LEFT_KNEE = 25
RIGHT_KNEE = 26



def pixel_distance(p1, p2, image_width, image_height):
    x1, y1 = p1.x * image_width, p1.y * image_height
    x2, y2 = p2.x * image_width, p2.y * image_height
    return math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)

def midpoint(p1, p2):
    return(
        (p1.x + p2.x) / 2,
        (p1.y + p2.y) / 2,
    )

def calculate_sleeve_length(landmarks,image_width,image_height):
    left = (
        pixel_distance(landmarks[LEFT_SHOULDER],landmarks[LEFT_ELBOW],image_width,image_height) + pixel_distance(landmarks[LEFT_ELBOW],landmarks[LEFT_WRIST],image_width,image_height)

    )

    right = (
        pixel_distance(landmarks[RIGHT_SHOULDER],landmarks[RIGHT_ELBOW],image_width,image_height) + pixel_distance(landmarks[RIGHT_ELBOW],landmarks[RIGHT_WRIST],image_width,image_height)

    )
    return (left + right) /2


def calculate_trouser_length(landmarks,image_width,image_height):
    left = (
        pixel_distance(
            landmarks[LEFT_HIP],
            landmarks[LEFT_KNEE],
            image_width,
            image_height
        ) 
        +
        pixel_distance(
            landmarks[LEFT_KNEE],
            landmarks[LEFT_ANKLE],
            image_width,
            image_height
        )

    )
    right = (
        pixel_distance(
            landmarks[RIGHT_HIP],
            landmarks[RIGHT_KNEE],
            image_width,
            image_height
        ) 
        +
        pixel_distance(
            landmarks[RIGHT_KNEE],
            landmarks[RIGHT_ANKLE],
            image_width,
            image_height
        )
        
    )
    return (left + right) /2




def calculate_shoulder_width(landmarks, image_width, image_height):
    return pixel_distance(landmarks[LEFT_SHOULDER], landmarks[RIGHT_SHOULDER], image_width, image_height)


def calculate_hip_width(landmarks, image_width, image_height):# To be improved
    return pixel_distance(landmarks[LEFT_HIP], landmarks[RIGHT_HIP], image_width, image_height)


def calculate_waist_to_knee(landmarks,image_width,image_height):
    left_hip = landmarks[LEFT_HIP]
    right_hip = landmarks[RIGHT_HIP]

    left_knee = landmarks[LEFT_KNEE]
    right_knee = landmarks[RIGHT_KNEE]

    waist = midpoint(left_hip,right_hip)
    knee = midpoint(left_knee,right_knee)

    x1 = waist[0] * image_width
    y1 = waist[1] * image_height

    x2 = knee[0] * image_width
    y2 = knee[1] * image_height

    return math.sqrt(
        (x2 - x1) ** 2 +
        (y2 - y1) ** 2
    )


def calculate_knee_width(landmarks,image_width,image_height):
    return pixel_distance(
        landmarks[LEFT_KNEE],
        landmarks[RIGHT_KNEE],
        image_width,
        image_height
    )

def calculate_shin_length(landmarks,image_width,image_height):
    left = pixel_distance(
        landmarks[LEFT_KNEE],
        landmarks[LEFT_ANKLE],
        image_width,
        image_height
    )

    right = pixel_distance(
        landmarks[RIGHT_KNEE],
        landmarks[RIGHT_ANKLE],
        image_width,
        image_height
    )
    
    return (left + right) / 2

def calculate_body_height_pixels(landmarks, image_width, image_height):  #To be improved
    nose = landmarks[NOSE]
    left_ankle = landmarks[LEFT_ANKLE]
    right_ankle = landmarks[RIGHT_ANKLE]

    nose_x = nose.x * image_width
    nose_y = nose.y * image_height
    ankle_mid_x = ((left_ankle.x + right_ankle.x) / 2) * image_width
    ankle_y = max(left_ankle.y, right_ankle.y) * image_height

    return math.sqrt((ankle_mid_x - nose_x) ** 2 + (ankle_y - nose_y) ** 2)


def convert_pixels_to_cm(pixel_measurement, scale_factor):
    return pixel_measurement * scale_factor
