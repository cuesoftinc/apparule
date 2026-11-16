"""apparule.notifications.created -> push and email (§6.5).

The NOTIFICATION row in common is the source of truth; delivery here is
best-effort and never retried into a stuck consumer. Push goes to every
device token through FCM, silent (data only) for capture results so a
backgrounded app refreshes. Money events also go by email through Brevo.
Social pushes (likes, follows, comments) coalesce per account over a window:
the first goes at once, the rest become one "N new …" push when it closes.
Nothing runs between requests (S-14), so a closed window is flushed inside a
request: by the next social notification, by POST /internal/settle, or at
shutdown.
"""

import logging
import time
from collections import OrderedDict, defaultdict

from notify.brevo import Brevo
from notify.fcm import FCM

log = logging.getLogger(__name__)

SOCIAL = {"like", "follow", "comment"}
SILENT = {"capture_result"}
TITLES = {"quote": "New quote", "status_change": "Order update", "payout": "Payout released", "like": "New like", "follow": "New follower", "comment": "New comment"}
NOUNS = {"like": "likes", "follow": "followers", "comment": "comments"}

# A redelivered message (a crash before the offset commit, or the outbox
# sending a row twice) must not push or email twice: delivered ids are kept
# for an hour, at most this many.
SEEN_TTL = 3600
SEEN_LIMIT = 20_000


class Notifier:
    def __init__(self, fcm: FCM | None, brevo: Brevo | None, window_seconds: int = 300):
        self._fcm = fcm
        self._brevo = brevo
        self._window = window_seconds
        # account -> kind -> (window start, pending count, tokens)
        self._social: dict[str, dict[str, list]] = defaultdict(dict)
        # notification id -> when it was delivered (monotonic), oldest first
        self._seen: OrderedDict[str, float] = OrderedDict()

    def _delivered(self, notification_id: str) -> bool:
        now = time.monotonic()
        while self._seen and (len(self._seen) > SEEN_LIMIT or now - next(iter(self._seen.values())) > SEEN_TTL):
            self._seen.popitem(last=False)
        return notification_id in self._seen

    async def deliver(self, msg: dict) -> None:
        notification_id = msg["notification_id"]
        if self._delivered(notification_id):
            log.info("duplicate notification skipped", extra={"notification_id": notification_id})
            return
        await self._deliver(msg)
        # Recorded after delivery: a handler that raised is retried, not skipped.
        self._seen[notification_id] = time.monotonic()

    async def _deliver(self, msg: dict) -> None:
        kind = msg["kind"]
        tokens = msg["recipient"].get("push_tokens", [])
        data = {"notification_id": msg["notification_id"], "kind": kind}
        if msg.get("ref"):
            data |= {"ref_kind": msg["ref"]["kind"], "ref_id": msg["ref"]["id"]}
        if kind in SOCIAL:
            await self.flush_due()  # a closed window must send its summary before a new one replaces it
            if self._coalesce(msg["account_id"], kind, tokens):
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
        return False

    async def flush_due(self, force: bool = False) -> int:
        """Sends the "N new …" push of every window that has closed (every
        open window when `force`) and answers how many it sent."""
        now = time.monotonic()
        sent = 0
        for account, kinds in list(self._social.items()):
            for kind, window in list(kinds.items()):
                if not force and now - window[0] < self._window:
                    continue
                del kinds[kind]
                if window[1] > 0 and self._fcm and window[2]:
                    try:
                        await self._fcm.send(window[2], title=TITLES[kind], body=f"{window[1]} new {NOUNS[kind]}", data={"kind": kind})
                    except Exception as exc:
                        log.warning("summary push failed", extra={"kind": kind, "error": type(exc).__name__})
                        continue
                    sent += 1
            if not kinds:
                del self._social[account]
        return sent

    async def aclose(self) -> None:
        await self.flush_due(force=True)
