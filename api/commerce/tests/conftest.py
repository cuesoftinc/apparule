import json
import os
from pathlib import Path

import httpx
import pytest

os.environ.setdefault("KAFKA_BROKERS", "localhost:9094")
os.environ.setdefault("STORAGE_BUCKET", "test-bucket")
os.environ.setdefault("STORAGE_PREFIX", "apparule/test")

from contract import Contract  # noqa: E402
from paystack import Paystack  # noqa: E402

CONTRACT_DIR = Path(os.environ.get("CONTRACT_DIR", Path(__file__).resolve().parents[2] / "common" / "contract"))


class MemoryStore:
    bucket = "test-bucket"

    def __init__(self):
        self.objects: dict[str, bytes] = {}

    async def get(self, key: str) -> bytes:
        return self.objects[key]

    async def put(self, key: str, data: bytes, content_type: str) -> None:
        self.objects[key] = data


@pytest.fixture(scope="session")
def contract() -> Contract:
    return Contract(CONTRACT_DIR)


@pytest.fixture
def store() -> MemoryStore:
    return MemoryStore()


def example(name: str) -> dict:
    return json.loads((CONTRACT_DIR / "examples" / f"{name}.json").read_text(encoding="utf-8"))


class FakePaystack:
    """Routes requests to canned responses; records what was called."""

    def __init__(self, routes: dict[tuple[str, str], tuple[int, dict]]):
        self.routes = routes
        self.calls: list[tuple[str, str, dict]] = []

    def handler(self, request: httpx.Request) -> httpx.Response:
        body = json.loads(request.content) if request.content else {}
        self.calls.append((request.method, request.url.path, body))
        status, payload = self.routes.get((request.method, request.url.path), (404, {"status": False, "message": "no route"}))
        return httpx.Response(status, json=payload)

    def client(self) -> Paystack:
        return Paystack("sk_test", client=httpx.AsyncClient(transport=httpx.MockTransport(self.handler)), backoff=0)


def ok(data) -> tuple[int, dict]:
    return 200, {"status": True, "message": "ok", "data": data}
