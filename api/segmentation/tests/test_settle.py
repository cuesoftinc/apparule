"""POST /internal/settle (S-14): who may call it, and the consumer draining inside it."""

import asyncio
from types import SimpleNamespace

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.config import Settings
from kafka.consumer import Consumer
from settle import BUDGET_SECONDS, router

COMMON = "apparule-common@p.iam.gserviceaccount.com"
AUDIENCE = "https://apparule-api-segmentation-1.us-central1.run.app"


def app_with(run, audience=AUDIENCE, invokers=(COMMON,), verify=None):
    app = FastAPI()
    kwargs = {"verify": verify} if verify else {}
    app.include_router(router(run, audience, list(invokers), **kwargs))
    return app


def token_for(email: str, verified: bool = True):
    def verify(token, audience):
        if token != "good":
            raise ValueError("bad token")
        return {"email": email, "email_verified": verified}

    return verify


async def caught_up(budget):
    return {"caught_up": True}


def post(client, token="good"):
    return client.post("/internal/settle", headers={"Authorization": f"Bearer {token}"} if token else {})


def test_settle_runs_inside_the_request_and_answers_whether_it_caught_up():
    seen = []

    async def run(budget):
        seen.append(budget)
        return {"caught_up": False}

    response = post(TestClient(app_with(run, verify=token_for(COMMON))))
    assert response.status_code == 200
    assert response.json()["caught_up"] is False and response.json()["ms"] >= 0
    assert seen == [BUDGET_SECONDS]


def test_settle_verifies_the_token_against_this_services_url():
    audiences = []

    def verify(token, audience):
        audiences.append(audience)
        return {"email": COMMON, "email_verified": True}

    post(TestClient(app_with(caught_up, audience=AUDIENCE + "/", verify=verify)))
    assert audiences == [AUDIENCE]


@pytest.mark.parametrize(("audience", "invokers"), [("", [COMMON]), (AUDIENCE, []), ("", [])])
def test_settle_is_refused_when_auth_is_not_configured(audience, invokers):
    assert post(TestClient(app_with(caught_up, audience=audience, invokers=invokers, verify=token_for(COMMON)))).status_code == 503


def test_settle_needs_a_valid_token():
    client = TestClient(app_with(caught_up, verify=token_for(COMMON)))
    assert post(client, token=None).status_code == 401
    assert client.post("/internal/settle", headers={"Authorization": "Basic good"}).status_code == 401
    assert post(client, token="forged").status_code == 401


def test_settle_refuses_another_account_and_an_unverified_email():
    assert post(TestClient(app_with(caught_up, verify=token_for("someone@else.iam.gserviceaccount.com")))).status_code == 403
    assert post(TestClient(app_with(caught_up, verify=token_for(COMMON, verified=False)))).status_code == 403


def test_a_failing_settle_is_a_500():
    async def run(budget):
        raise RuntimeError("boom")

    assert post(TestClient(app_with(run, verify=token_for(COMMON)))).status_code == 500


def test_settings_tell_cloud_run_and_list_the_invokers():
    settings = Settings(_env_file=None, k_service="apparule-api-segmentation", internal_invokers=f" {COMMON} , other@p.iam.gserviceaccount.com ,")
    assert settings.on_cloud_run and settings.internal_invoker_list == [COMMON, "other@p.iam.gserviceaccount.com"]
    assert not Settings(_env_file=None, k_service="").on_cloud_run


class FakeKafka:
    """Three records waiting on one partition; committed trails what was handed out."""

    def __init__(self, count: int):
        self.count = count
        self.delivered = 0
        self.committed_to = 0
        self.fail_commit = False

    def partitions_for_topic(self, topic):
        return {0}

    async def end_offsets(self, tps):
        return {tp: self.count for tp in tps}

    async def beginning_offsets(self, tps):
        return {tp: 0 for tp in tps}

    async def committed(self, tp):
        return self.committed_to or None

    async def getmany(self, timeout_ms, max_records):
        if self.delivered >= self.count:
            await asyncio.sleep(timeout_ms / 1000)
            return {}
        assert max_records == 1  # commit() must cover only the record just handled
        self.delivered += 1
        return {"tp": [SimpleNamespace(topic="cuelabs.requests", value={"n": self.delivered}, offset=self.delivered - 1)]}

    async def commit(self):
        if self.fail_commit:
            raise RuntimeError("commit failed")
        self.committed_to = self.delivered


class Handled:
    def __init__(self):
        self.values = []

    async def handle(self, topic, value):
        self.values.append(value["n"])


def consumer_over(fake, background=False):
    c = Consumer.__new__(Consumer)
    c.group = "segmentation"
    c._topics = ["cuelabs.requests"]
    c._consumer = fake
    c._dispatcher = Handled()
    c._background = background
    c._lock = asyncio.Lock()
    c._task = None
    c.running = False
    return c


async def test_drain_handles_what_is_waiting_commits_each_and_reports_caught_up():
    fake = FakeKafka(3)
    c = consumer_over(fake)
    assert await c.drain(5.0) is True
    assert c._dispatcher.values == [1, 2, 3] and fake.committed_to == 3


async def test_drain_says_it_is_behind_when_the_budget_ends_first():
    fake = FakeKafka(3)
    fake.fail_commit = True  # nothing ever commits, so the lag never closes
    c = consumer_over(fake)
    assert await c.drain(0.2) is False
    assert c._dispatcher.values == [1, 2, 3]  # a failed commit means redelivery, not a stop


async def test_drain_with_nothing_waiting_returns_at_once():
    c = consumer_over(FakeKafka(0))
    assert await asyncio.wait_for(c.drain(5.0), timeout=1.0) is True


async def test_two_settles_do_not_fetch_at_the_same_time():
    fake = FakeKafka(2)
    c = consumer_over(fake)
    first, second = await asyncio.gather(c.drain(5.0), c.drain(5.0))
    assert first and second and c._dispatcher.values == [1, 2]


async def test_without_the_background_loop_start_creates_no_task():
    class Started:
        async def start(self):
            pass

    c = consumer_over(Started())
    before = asyncio.all_tasks()
    await c.start()
    assert c._task is None and c.running and asyncio.all_tasks() == before


async def test_with_the_background_loop_drain_only_waits_for_it():
    fake = FakeKafka(2)
    c = consumer_over(fake, background=True)
    c._task = object()  # the loop is consuming; drain must not fetch beside it
    fake.committed_to = 2
    assert await c.drain(1.0) is True
    assert c._dispatcher.values == [] and fake.delivered == 0
