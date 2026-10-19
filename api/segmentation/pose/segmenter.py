import mediapipe as mp
import numpy as np
from mediapipe.tasks import python
from mediapipe.tasks.python import vision


class BodySegmenter:
    def __init__(self, model_path: str):
        base_options = python.BaseOptions(model_asset_path=model_path)

        options = vision.ImageSegmenterOptions(
            base_options=base_options,
            running_mode=vision.RunningMode.IMAGE,
            output_category_mask=True,
        )

        self._segmenter = vision.ImageSegmenter.create_from_options(options)

    def segment(self, mp_image: mp.Image):
        # run body segmentation on a mediapipe image
        return self._segmenter.segment(mp_image)

    def person_mask(self, mp_image: mp.Image) -> np.ndarray:
        """A boolean mask, True where the person is. The selfie segmenter's
        category mask is 0 on the person (demo_segment.py inverts it the same
        way)."""
        mask = self.segment(mp_image).category_mask.numpy_view()
        return mask == 0

    def close(self):
        self._segmenter.close()
