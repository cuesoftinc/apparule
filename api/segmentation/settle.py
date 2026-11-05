"""POST /internal/settle: handle everything waiting for this service, then answer (S-14).

Cloud Run gives this service CPU only while it serves a request, so its Kafka
consumer cannot work between requests. api/common calls settle after it
publishes for this service and at the end of every captures pass; the
consumer drains inside that request, within BUDGET_SECONDS, and the answer
says whether it caught up. What is cut off waits for the next pass.

Callers are checked here as well as by Cloud Run IAM: the Google ID token
api/common sends for INTERNAL_AUDIENCE (this service's URL), from one of
INTERNAL_INVOKERS. With either unset every call is refused.
"""

import asyncio
import logging
import time
from collections.abc import Awaitable, Callable, Sequence

from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse

log = logging.getLogger(__name__)

# api/common waits up to 25 s for the answer.
BUDGET_SECONDS = 20.0


def verify_google_token(token: str, audience: str) -> dict:
    import google.auth.transport.requests
    import google.oauth2.id_token

    return google.oauth2.id_token.verify_oauth2_token(token, google.auth.transport.requests.Request(), audience)


def _error(status: int, code: str, message: str) -> JSONResponse:
    return JSONResponse({"error": {"code": code, "message": message, "details": {}}}, status_code=status)


def router(run: Callable[[float], Awaitable[dict]], audience: str, invokers: Sequence[str], verify=verify_google_token) -> APIRouter:
    """`run(budget)` does one settle and answers {"caught_up": bool, ...}."""
    r = APIRouter()

    @r.post("/internal/settle")
    async def settle(request: Request):
        if not audience or not invokers:
            log.error("settle auth not configured")
            return _error(503, "unavailable", "Internal auth is not configured")
        scheme, _, token = request.headers.get("authorization", "").partition(" ")
        if scheme.lower() != "bearer" or not token.strip():
            return _error(401, "unauthorized", "Missing bearer token")
        try:
            claims = await asyncio.to_thread(verify, token.strip(), audience.rstrip("/"))
        except Exception:
            log.warning("settle token rejected")
            return _error(401, "unauthorized", "Invalid token")
        if not claims.get("email_verified") or claims.get("email") not in invokers:
            return _error(403, "forbidden", "Caller is not allowed")
        started = time.monotonic()
        try:
            out = await run(BUDGET_SECONDS)
        except Exception:
            log.exception("settle failed")
            return _error(500, "internal", "Something went wrong")
        out = {**out, "ms": int((time.monotonic() - started) * 1000)}
        log.info("settled", extra={"step": "settle", **out})
        return out

    return r
