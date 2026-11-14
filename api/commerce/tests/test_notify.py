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


async def test_social_pushes_coalesce_over_the_window():
    fcm = FakeFCM()
    notifier = Notifier(fcm, None, window_seconds=0.05)
    for i in range(4):
        msg = _msg(kind="like", ref={"kind": "post", "id": "p1"}, notification_id=f"n{i}")
        msg.pop("money")
        await notifier.deliver(msg)
    assert len(fcm.sent) == 1  # the first goes at once
    await asyncio.sleep(0.1)
    assert fcm.sent[-1]["body"] == "3 new likes"
    await notifier.aclose()


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


async def test_a_redelivered_notification_is_not_pushed_or_emailed_twice():
    fcm, brevo = FakeFCM(), FakeBrevo()
    notifier = Notifier(fcm, brevo)
    msg = _msg()
    msg["recipient"]["email"] = "tolu@example.com"
    await notifier.deliver(msg)
    await notifier.deliver(copy.deepcopy(msg))
    assert len(fcm.sent) == 1 and len(brevo.sent) == 1
    other = _msg(notification_id="another")
    other["recipient"]["email"] = "tolu@example.com"
    await notifier.deliver(other)
    assert len(fcm.sent) == 2 and len(brevo.sent) == 2


async def test_a_failed_delivery_is_retried_not_remembered():
    class Flaky(FakeFCM):
        calls = 0

        async def send(self, tokens, title=None, body=None, data=None):
            Flaky.calls += 1
            if Flaky.calls == 1:
                raise RuntimeError("fcm down")
            return await super().send(tokens, title, body, data)

    fcm = Flaky()
    notifier = Notifier(fcm, None)
    msg = _msg()
    try:
        await notifier.deliver(msg)
    except RuntimeError:
        pass
    await notifier.deliver(msg)
    assert len(fcm.sent) == 1
