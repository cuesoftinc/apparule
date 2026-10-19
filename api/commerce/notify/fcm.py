"""Firebase Cloud Messaging, HTTP v1, with Application Default Credentials
(Cloud Run's service account needs Firebase Cloud Messaging API Admin)."""

import asyncio
import logging

import google.auth
import google.auth.transport.requests
import httpx

log = logging.getLogger(__name__)

SCOPE = "https://www.googleapis.com/auth/firebase.messaging"


class FCM:
    def __init__(self, project_id: str, client: httpx.AsyncClient | None = None, credentials=None):
        self._url = f"https://fcm.googleapis.com/v1/projects/{project_id}/messages:send"
        self._client = client or httpx.AsyncClient(timeout=10.0)
        self._credentials = credentials

    async def _token(self) -> str:
        if self._credentials is None:
            self._credentials, _ = google.auth.default(scopes=[SCOPE])
        if not self._credentials.valid:
            await asyncio.to_thread(self._credentials.refresh, google.auth.transport.requests.Request())
        return self._credentials.token

    async def send(self, tokens: list[str], title: str | None = None, body: str | None = None, data: dict | None = None) -> int:
        """Sends one message per device; returns how many FCM accepted.
        Failures are logged by status only, never with the token."""
        headers = {"Authorization": f"Bearer {await self._token()}"}
        sent = 0
        for token in tokens:
            message: dict = {"token": token, "data": {k: str(v) for k, v in (data or {}).items()}}
            if title:
                message["notification"] = {"title": title, "body": body or ""}
            else:
                message["apns"] = {"headers": {"apns-push-type": "background", "apns-priority": "5"},
                                   "payload": {"aps": {"content-available": 1}}}
                message["android"] = {"priority": "normal"}
            try:
                response = await self._client.post(self._url, headers=headers, json={"message": message})
            except httpx.HTTPError as exc:
                log.warning("push failed", extra={"step": "fcm", "error": type(exc).__name__})
                continue
            if response.status_code == 200:
                sent += 1
            else:
                log.warning("push refused", extra={"step": "fcm", "status": response.status_code})
        return sent

    async def aclose(self) -> None:
        await self._client.aclose()
