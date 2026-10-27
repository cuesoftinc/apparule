"""api/commerce: money decisions and notification delivery (system-design.md §4).

No public ingress. HTTP serves only /health and /ready; the work arrives over
Kafka. Money (S-6): Paystack events, payouts, refunds, bank-account
verification and reconciliation, each answered with apparule.payments.outcome.
Notify (S-7): push and email for every notification row common writes.
Without a Paystack secret it runs notify-only (self-host, §10.2). In cloud it
scales to zero: common wakes it after publishing, and it wakes common after
each outcome.
"""

import logging
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI

import payouts
import reconcile
from app.config import get_settings
from contract import Contract
from health import router as health_router
from kafka import topics
from kafka.consumer import Consumer
from kafka.producer import Producer
from kafka.wake import Waker
from notify import Notifier
from notify.brevo import Brevo
from notify.fcm import FCM
from payments import settle
from payments.failed import failed_outcome
from payments.movements import Movements
from paystack import Paystack
from storage import from_settings
from telemetry import configure as configure_logging

log = logging.getLogger("commerce")


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = get_settings()
    configure_logging(settings.log_level)
    contract = Contract(settings.contract_dir)
    store = from_settings(settings)
    producer = Producer(settings, contract, store)
    waker = Waker(settings.wake_common_url)
    fcm = FCM(settings.fcm_project_id) if settings.fcm_project_id else None
    brevo = Brevo(settings.brevo_api_key, settings.brevo_from_email, settings.brevo_from_name) if settings.brevo_api_key else None
    notifier = Notifier(fcm, brevo, settings.social_window_seconds)
    paystack = Paystack(settings.paystack_secret_key, settings.paystack_base_url) if settings.payments_enabled else None
    log.info("starting", extra={"payments": paystack is not None, "push": fcm is not None, "email": brevo is not None})

    async def send(outcome: dict | None, key: str, step: str, started: float, request_id: str | None) -> None:
        if outcome is None:
            return
        await producer.send(topics.PAYMENTS_OUTCOME, key, outcome, request_id)
        waker.soon(topics.PAYMENTS_OUTCOME)
        log.info("outcome sent", extra={"step": step, "kind": outcome["kind"], "outcome_id": outcome["outcome_id"],
                                        "reason": outcome.get("reason"), "ms": round((time.monotonic() - started) * 1000)})

    async def on_notification(msg: dict, request_id: str | None) -> None:
        await notifier.deliver(msg)
        log.info("notification delivered", extra={"step": "notify", "kind": msg["kind"], "notification_id": msg["notification_id"]})

    handlers = {topics.NOTIFICATION_CREATED: on_notification}

    if paystack is not None:
        movements = Movements(paystack, settings.platform_fee_bps)

        async def on_provider_event(msg: dict, request_id: str | None) -> None:
            start = time.monotonic()
            outcome = settle.decide(msg, settings.platform_fee_bps)
            key = outcome.get("request_id", msg["provider_event_id"]) if outcome else ""
            await send(outcome, key, "payments.provider_event", start, request_id)

        async def on_transition(msg: dict, request_id: str | None) -> None:
            start = time.monotonic()
            await send(await movements.on_transition(msg), msg["request_id"], "orders.transition", start, request_id)

        async def on_recipient(msg: dict, request_id: str | None) -> None:
            start = time.monotonic()
            await send(await payouts.verify(paystack, msg), msg["designer_id"], "payouts.recipient_requested", start, request_id)

        async def on_reconcile(msg: dict, request_id: str | None) -> None:
            start = time.monotonic()
            mismatches = await reconcile.compare(paystack, msg)
            for outcome in mismatches:
                await send(outcome, "reconcile", "ledger.reconcile_requested", start, request_id)
            log.info("reconciled", extra={"step": "reconcile", "movements": len(msg["movements"]), "mismatches": len(mismatches)})

        handlers |= {topics.PROVIDER_EVENT: on_provider_event, topics.ORDERS_TRANSITION: on_transition,
                     topics.RECIPIENT_REQUESTED: on_recipient, topics.RECONCILE_REQUESTED: on_reconcile}

    async def on_failure(event: str, msg: dict, request_id: str | None) -> None:
        outcome = failed_outcome(event, msg)
        if outcome is None:
            return  # nothing to decide: logged by the consumer and dropped
        key = outcome.get("request_id") or outcome.get("designer_id") or ""
        await send(outcome, key, event.removeprefix("apparule."), time.monotonic(), request_id)

    consumer = Consumer("commerce", handlers, settings, contract, store, on_failure)
    await producer.start()
    await consumer.start()
    app.state.consumers = [consumer]
    try:
        yield
    finally:
        await consumer.stop()
        await producer.stop()
        await waker.aclose()
        await notifier.aclose()
        for client in (paystack, fcm, brevo):
            if client is not None:
                await client.aclose()


app = FastAPI(title="apparule-api-commerce", lifespan=lifespan, docs_url=None, redoc_url=None, openapi_url=None)
app.include_router(health_router)
