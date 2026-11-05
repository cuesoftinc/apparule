import asyncio
import copy

import google.auth.exceptions
import httpx

from notify import Notifier
from notify.fcm import FCM
from tests.conftest import example


class FakeFCM:
    def __init__(self):
        self.sent: list[dict] = []

    async def send(self, tokens, title=None, body=None, data=None):
        self.sent.append({"tokens": tokens, "title": title, "body": body, "data": data})
        return len(tokens)

    async def aclose(self):
        pass


class FakeBrevo:
    def __init__(self):
        self.sent: list[tuple] = []

    async def send(self, to_email, to_name, subject, text):
        self.sent.append((to_email, subject, text))
        return True


def _msg(**changes) -> dict:
    msg = copy.deepcopy(example("notifications.created")["data"])
    msg.update(changes)
    return msg


async def test_push_with_title_and_money_email():
    fcm, brevo = FakeFCM(), FakeBrevo()
    msg = _msg()
    msg["recipient"]["email"] = "tolu@example.com"
    await Notifier(fcm, brevo).deliver(msg)
    assert fcm.sent[0]["title"] == "New quote" and fcm.sent[0]["data"]["ref_id"] == msg["ref"]["id"]
    assert brevo.sent == [("tolu@example.com", "New quote", msg["text"])]


async def test_capture_results_go_silent_and_without_email():
    fcm, brevo = FakeFCM(), FakeBrevo()
    msg = _msg(kind="capture_result", ref={"kind": "session", "id": "s1"})
    msg.pop("money")
    await Notifier(fcm, brevo).deliver(msg)
    assert fcm.sent[0]["title"] is None and brevo.sent == []


def _like() -> dict:
    msg = _msg(kind="like", ref={"kind": "post", "id": "p1"})
    msg.pop("money")
    return msg


async def test_social_pushes_coalesce_until_the_window_is_flushed():
    fcm = FakeFCM()
    notifier = Notifier(fcm, None, window_seconds=0.05)
    for _ in range(4):
        await notifier.deliver(_like())
    assert len(fcm.sent) == 1  # the first goes at once
    assert await notifier.flush_due() == 0  # the window is still open
    await asyncio.sleep(0.1)
    assert await notifier.flush_due() == 1
    assert fcm.sent[-1]["body"] == "3 new likes"
    assert await notifier.flush_due() == 0


async def test_a_social_notification_leaves_no_task_to_run_after_the_response():
    notifier = Notifier(FakeFCM(), None, window_seconds=0.05)
    before = asyncio.all_tasks()
    await notifier.deliver(_like())
    await notifier.deliver(_like())
    assert asyncio.all_tasks() == before


async def test_a_closed_window_is_sent_before_a_new_one_replaces_it():
    fcm = FakeFCM()
    notifier = Notifier(fcm, None, window_seconds=0.05)
    for _ in range(3):
        await notifier.deliver(_like())
    await asyncio.sleep(0.1)
    await notifier.deliver(_like())
    assert [s["body"] for s in fcm.sent][1] == "2 new likes"
    assert len(fcm.sent) == 3  # the first push, the summary, then the new window's first push


async def test_closing_the_notifier_sends_every_open_summary():
    fcm = FakeFCM()
    notifier = Notifier(fcm, None, window_seconds=300)
    await notifier.deliver(_like())
    await notifier.deliver(_like())
    await notifier.aclose()
    assert fcm.sent[-1]["body"] == "1 new likes" and await notifier.flush_due(force=True) == 0


async def test_a_failing_summary_push_does_not_fail_the_flush():
    class Down(FakeFCM):
        async def send(self, tokens, title=None, body=None, data=None):
            if body and body.endswith("new likes"):
                raise RuntimeError("fcm away")
            return await super().send(tokens, title, body, data)

    notifier = Notifier(Down(), None, window_seconds=0.01)
    await notifier.deliver(_like())
    await notifier.deliver(_like())
    await asyncio.sleep(0.05)
    assert await notifier.flush_due() == 0


async def test_no_tokens_no_push():
    fcm = FakeFCM()
    msg = _msg()
    msg["recipient"]["push_tokens"] = []
    await Notifier(fcm, None).deliver(msg)
    assert fcm.sent == []


class RefusingCredentials:
    valid = False

    def refresh(self, request):
        raise google.auth.exceptions.RefreshError("no access")


async def test_push_auth_failure_is_logged_not_raised():
    async with httpx.AsyncClient() as client:
        fcm = FCM("apparule", client=client, credentials=RefusingCredentials())
        assert await fcm.send(["device-1"], title="New quote", body="", data={}) == 0
