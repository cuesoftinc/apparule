
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision



class BodySegmenter:
    def __init__(self,model_path: str):
        base_options = python.BaseOptions(
            model_asset_path = model_path
        )

        options = vision.ImageSegmenterOptions(
            base_options = base_options,
            running_mode = vision.RunningMode.IMAGE,
            output_category_mask = True,
        )    

        self._segmenter =vision.ImageSegmenter.create_from_options(
            options
        )

    def segment(self,mp_image: mp.Image):
        #run body segmentation on a mdeiapipe image
        result = self._segmenter.segment(mp_image)
        return result

    def clode(self):
        self._segmenter.close()