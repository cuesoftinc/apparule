from types import SimpleNamespace

import httpx
import pytest
from fastapi import FastAPI

from health import router


@pytest.fixture
def app() -> FastAPI:
    application = FastAPI()
    application.include_router(router)
    return application


async def request(app: FastAPI, path: str) -> httpx.Response:
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        return await client.get(path)


async def test_health_reports_healthy(app: FastAPI):
    response = await request(app, "/health")

    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}


@pytest.mark.parametrize("consumers", [[], [SimpleNamespace(running=False)]])
async def test_ready_reports_not_ready_without_running_consumers(app: FastAPI, consumers):
    app.state.consumers = consumers

    response = await request(app, "/ready")

    assert response.status_code == 503
    assert response.json() == {"status": "not_ready"}


async def test_ready_reports_ready_when_all_consumers_are_running(app: FastAPI):
    app.state.consumers = [
        SimpleNamespace(running=True),
        SimpleNamespace(running=True),
    ]

    response = await request(app, "/ready")

    assert response.status_code == 200
    assert response.json() == {"status": "ready"}


async def test_ready_reports_not_ready_when_any_consumer_is_stopped(app: FastAPI):
    app.state.consumers = [
        SimpleNamespace(running=True),
        SimpleNamespace(running=False),
    ]

    response = await request(app, "/ready")

    assert response.status_code == 503
    assert response.json() == {"status": "not_ready"}
