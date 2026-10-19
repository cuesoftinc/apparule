"""Brevo transactional email, for money events only (§6.5)."""

import html
import logging

import httpx

log = logging.getLogger(__name__)


class Brevo:
    def __init__(self, api_key: str, from_email: str, from_name: str, client: httpx.AsyncClient | None = None):
        self._client = client or httpx.AsyncClient(timeout=10.0)
        self._headers = {"api-key": api_key, "Content-Type": "application/json", "Accept": "application/json"}
        self._sender = {"email": from_email, "name": from_name}

    async def send(self, to_email: str, to_name: str, subject: str, text: str) -> bool:
        body = {
            "sender": self._sender,
            "to": [{"email": to_email, "name": to_name or to_email}],
            "subject": subject,
            "textContent": text,
            "htmlContent": f"<p>{html.escape(text)}</p><p>— Apparule</p>",
        }
        try:
            response = await self._client.post("https://api.brevo.com/v3/smtp/email", headers=self._headers, json=body)
        except httpx.HTTPError as exc:
            log.warning("email failed", extra={"step": "brevo", "error": type(exc).__name__})
            return False
        if response.status_code >= 300:
            log.warning("email refused", extra={"step": "brevo", "status": response.status_code})
            return False
        return True

    async def aclose(self) -> None:
        await self._client.aclose()
