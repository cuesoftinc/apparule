"""api/segmentation: pose QC and measurements (system-design.md §4).

No public ingress. HTTP serves only /health and /ready; the work arrives over
Kafka as capture.ready and leaves as capture.measured. In cloud the service
scales to zero: common wakes it after publishing for it, and it wakes common
after sending a result (shared-messaging.md, "Scale to zero").
"""

import logging
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.config import QC, get_settings
from contract import Contract
from health import router as health_router
from kafka import topics
from kafka.consumer import Consumer
from kafka.producer import Producer
from kafka.wake import Waker
from pipeline import CapturePipeline
from pose.detector import PoseAnalyzer
from storage import from_settings
from telemetry import configure as configure_logging

log = logging.getLogger("segmentation")


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = get_settings()
    configure_logging(settings.log_level)
    log.info("starting", extra={"thresholds_version": QC.version, "pose_model": settings.pose_model_path,
                                "segmentation_model": settings.segmentation_model_path})

    contract = Contract(settings.contract_dir)
    store = from_settings(settings)
    producer = Producer(settings, contract, store)
    waker = Waker(settings.wake_common_url)
    analyzer = PoseAnalyzer(settings.pose_model_path, settings.segmentation_model_path)
    pipeline = CapturePipeline(store, analyzer)

    async def on_capture_ready(msg: dict) -> None:
        start = time.monotonic()
        log.info("capture received", extra={"step": "capture.ready", "session_id": msg["session_id"],
                                            "attempt": msg["attempt"], "template": msg["template"]})
        result = await pipeline.run(msg)
        await producer.send(topics.CAPTURE_MEASURED, msg["session_id"], result)
        waker.soon(topics.CAPTURE_MEASURED)
        log.info("capture measured; result sent", extra={
            "step": "capture.measured", "session_id": msg["session_id"], "status": result["status"],
            "qc_code": result.get("qc", {}).get("code"), "qc_pose": result.get("qc", {}).get("pose"),
            "measures": len(result.get("measurements", [])), "ms": round((time.monotonic() - start) * 1000)})

    consumer = Consumer("capture", {topics.CAPTURE_READY: on_capture_ready}, settings, contract, store)

    await producer.start()
    await consumer.start()
    app.state.consumers = [consumer]
    try:
        yield
    finally:
        await consumer.stop()
        await producer.stop()
        await waker.aclose()
        analyzer.close()


app = FastAPI(title="apparule-api-segmentation", lifespan=lifespan, docs_url=None, redoc_url=None, openapi_url=None)
app.include_router(health_router)
