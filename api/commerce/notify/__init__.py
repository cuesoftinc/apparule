"""apparule.notifications.created -> push and email (§6.5).

The NOTIFICATION row in common is the source of truth; delivery here is
best-effort and never retried into a stuck consumer. Push goes to every
device token through FCM, silent (data only) for capture results so a
backgrounded app refreshes. Money events also go by email through Brevo.
Social pushes (likes, follows, comments) coalesce per account over a window:
the first goes at once, the rest become one "N new …" push when it closes.
"""

import asyncio
import logging
import time
from collections import defaultdict

from notify.brevo import Brevo
from notify.fcm import FCM

log = logging.getLogger(__name__)

SOCIAL = {"like", "follow", "comment"}
SILENT = {"capture_result"}
TITLES = {"quote": "New quote", "status_change": "Order update", "payout": "Payout released", "like": "New like",
          "follow": "New follower", "comment": "New comment"}
NOUNS = {"like": "likes", "follow": "followers", "comment": "comments"}


class Notifier:
    def __init__(self, fcm: FCM | None, brevo: Brevo | None, window_seconds: int = 300):
        self._fcm = fcm
        self._brevo = brevo
        self._window = window_seconds
        # account -> kind -> (window start, pending count, tokens)
        self._social: dict[str, dict[str, list]] = defaultdict(dict)
        self._tasks: set[asyncio.Task] = set()

    async def deliver(self, msg: dict) -> None:
        kind = msg["kind"]
        tokens = msg["recipient"].get("push_tokens", [])
        data = {"notification_id": msg["notification_id"], "kind": kind}
        if msg.get("ref"):
            data |= {"ref_kind": msg["ref"]["kind"], "ref_id": msg["ref"]["id"]}
        if kind in SOCIAL and self._coalesce(msg["account_id"], kind, tokens):
            return
        if self._fcm and tokens:
            if kind in SILENT:
                await self._fcm.send(tokens, data=data)
            else:
                await self._fcm.send(tokens, title=TITLES.get(kind, "Apparule"), body=msg.get("text", ""), data=data)
        email = msg["recipient"].get("email")
        if self._brevo and email and msg.get("money"):
            await self._brevo.send(email, msg["recipient"].get("display_name", ""), TITLES.get(kind, "Apparule"), msg.get("text", ""))

    def _coalesce(self, account: str, kind: str, tokens: list[str]) -> bool:
        """True when the push was absorbed into an open window."""
        now = time.monotonic()
        window = self._social[account].get(kind)
        if window and now - window[0] < self._window:
            window[1] += 1
            window[2] = tokens or window[2]
            return True
        self._social[account][kind] = [now, 0, tokens]
        task = asyncio.create_task(self._flush_later(account, kind))
        self._tasks.add(task)
        task.add_done_callback(self._tasks.discard)
        return False

    async def _flush_later(self, account: str, kind: str) -> None:
        await asyncio.sleep(self._window)
        window = self._social[account].pop(kind, None)
        if window and window[1] > 0 and self._fcm and window[2]:
            await self._fcm.send(window[2], title=TITLES[kind], body=f"{window[1]} new {NOUNS[kind]}", data={"kind": kind})

    async def aclose(self) -> None:
        for task in list(self._tasks):
            task.cancel()
