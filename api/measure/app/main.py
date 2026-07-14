import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.config import settings
from app.router import measure
from app.service.pose import PoseMeasurer

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s %(name)s: %(message)s",
)
logger = logging.getLogger("measure")


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("loading pose model from %s", settings.model_path)
    app.state.measurer = PoseMeasurer(settings.model_path)
    yield
    app.state.measurer.close()


app = FastAPI(title="Apparule Measure Service", lifespan=lifespan)
app.include_router(measure.router)


@app.get("/health")
def health():
    return {"status": "healthy", "service": "measure"}


@app.get("/ready")
def ready():
    return {"status": "ready"}
