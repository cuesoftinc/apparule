"""A small Paystack API client: only the calls commerce makes (§6.3, §6.4,
pages.md B8). Every money call carries an idempotency reference derived from
the order's transition, so a consumer restart can never pay twice."""

import asyncio
import logging

import httpx

log = logging.getLogger(__name__)


class PaystackError(Exception):
    """Paystack refused the request (a definite no, not an outage)."""

    def __init__(self, message: str, status: int = 400):
        super().__init__(message)
        self.status = status


class PaystackUnavailable(Exception):
    """Paystack could not be reached or answered 5xx after retries."""


class Paystack:
    def __init__(self, secret_key: str, base_url: str = "https://api.paystack.co", client: httpx.AsyncClient | None = None,
                 retries: int = 3, backoff: float = 1.0):
        self._client = client or httpx.AsyncClient(timeout=20.0)
        self._base = base_url.rstrip("/")
        self._headers = {"Authorization": f"Bearer {secret_key}", "Content-Type": "application/json"}
        self._retries = retries
        self._backoff = backoff

    async def _call(self, method: str, path: str, **kwargs) -> dict:
        for attempt in range(self._retries):
            try:
                response = await self._client.request(method, self._base + path, headers=self._headers, **kwargs)
            except httpx.HTTPError as exc:
                log.warning("paystack unreachable", extra={"path": path.split("?")[0], "error": type(exc).__name__, "attempt": attempt + 1})
            else:
                if response.status_code < 500:
                    body = response.json() if response.content else {}
                    if response.status_code >= 400 or body.get("status") is False:
                        raise PaystackError(body.get("message", "refused"), response.status_code)
                    return body.get("data") or {}
                log.warning("paystack 5xx", extra={"path": path.split("?")[0], "status": response.status_code, "attempt": attempt + 1})
            await asyncio.sleep(self._backoff * (2**attempt))
        raise PaystackUnavailable(path.split("?")[0])

    async def resolve_account(self, account_number: str, bank_code: str) -> dict:
        return await self._call("GET", "/bank/resolve", params={"account_number": account_number, "bank_code": bank_code})

    async def create_recipient(self, name: str, account_number: str, bank_code: str) -> dict:
        return await self._call("POST", "/transferrecipient", json={
            "type": "nuban", "name": name, "account_number": account_number, "bank_code": bank_code, "currency": "NGN"})

    async def transfer(self, amount: int, recipient_code: str, reference: str, reason: str) -> dict:
        return await self._call("POST", "/transfer", json={
            "source": "balance", "amount": amount, "recipient": recipient_code, "reference": reference, "reason": reason})

    async def refund(self, transaction: str, amount: int) -> dict:
        return await self._call("POST", "/refund", json={"transaction": transaction, "amount": amount})

    async def transactions(self, start: str, end: str) -> list[dict]:
        return await self._list("/transaction", {"from": start, "to": end, "status": "success"})

    async def transfers(self, start: str, end: str) -> list[dict]:
        return await self._list("/transfer", {"from": start, "to": end})

    async def refunds(self, start: str, end: str) -> list[dict]:
        return await self._list("/refund", {"from": start, "to": end})

    async def _list(self, path: str, params: dict) -> list[dict]:
        out: list[dict] = []
        page = 1
        while True:
            data = await self._call("GET", path, params={**params, "perPage": 100, "page": page})
            items = data if isinstance(data, list) else []
            out.extend(items)
            if len(items) < 100:
                return out
            page += 1

    async def aclose(self) -> None:
        await self._client.aclose()
