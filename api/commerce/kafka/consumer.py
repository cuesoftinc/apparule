"""One consumer group per service (apparule-<service>). It subscribes to the topics its
events travel on and routes each message on the envelope's type. Offsets are
committed after the handler finishes, so a crash mid-message redelivers it
(at-least-once); every handler is idempotent by key (system-design.md §9.2).
A handler that keeps failing is retried with backoff, answered with a failed
result where the event is a request, and committed: the lanes are shared, so
a stuck partition would stall every product on them (shared-messaging.md
rule 10)."""

import asyncio
import contextlib
import json
import logging
from collections.abc import Awaitable, Callable

from aiokafka import AIOKafkaConsumer

from app.config import Settings
from contract import Contract, ContractError
from kafka import envelope
from kafka.client import connection_kwargs
from kafka.topics import TOPIC_FOR
from storage import ObjectStore

log = logging.getLogger(__name__)

# A handler gets the payload and the request_id its results must carry.
Handler = Callable[[dict, str | None], Awaitable[None]]
# Called with (event, data, request_id) once a handler has kept failing.
FailureHandler = Callable[[str, dict, str | None], Awaitable[None]]

ATTEMPTS = 3
BACKOFF_SECONDS = 1.0


def _decode(value: bytes) -> object:
    """JSON, or None for anything else on the shared lanes."""
    try:
        return json.loads(value.decode())
    except (UnicodeDecodeError, ValueError):
        return None


class Dispatcher:
    """Routes one record to its handler; never raises, so the consumer
    always commits and moves on."""

    def __init__(
        self,
        handlers: dict[str, Handler],
        contract: Contract,
        store: ObjectStore,
        on_failure: FailureHandler | None = None,
        attempts: int = ATTEMPTS,
        backoff: float = BACKOFF_SECONDS,
    ):
        self.handlers = handlers
        self._contract = contract
        self._store = store
        self._on_failure = on_failure
        self._attempts = attempts
        self._backoff = backoff

    async def handle(self, topic: str, value: object) -> None:
        event = envelope.event_of(value)
        if event not in self.handlers:
            # The lanes are shared: another product's event, or one another
            # pool handles. Skip it without a word.
            return
        request_id = value.get("request_id") if isinstance(value, dict) else None
        data: dict | None = None
        error: Exception | None = None
        for attempt in range(1, self._attempts + 1):
            try:
                event, data, request_id = await envelope.unwrap(topic, value, self._contract, self._store)
            except (ContractError, ValueError, KeyError):
                # Can never succeed. Never log the payload (never-log list).
                log.exception("dropping invalid message", extra={"topic": topic, "request_id": request_id})
                return
            except Exception as exc:  # storage: worth another try
                error = exc
            else:
                try:
                    await self.handlers[event](data, request_id)
                    return
                except Exception as exc:
                    error = exc
            if attempt < self._attempts:
                log.warning("handler failed; retrying", extra={"topic": topic, "event": event, "request_id": request_id,
                                                               "attempt": attempt, "error": type(error).__name__})
                await asyncio.sleep(self._backoff * 2 ** (attempt - 1))
        log.error("handler kept failing; recorded and skipped", exc_info=error,
                  extra={"topic": topic, "event": event, "request_id": request_id, "attempts": self._attempts})
        if self._on_failure is not None and data is not None:
            try:
                await self._on_failure(event, data, request_id)
            except Exception:
                log.exception("recording the failure failed", extra={"event": event, "request_id": request_id})


class Consumer:
    """`handlers` maps each event this pool handles to its handler;
    `on_failure` answers a request whose handler kept failing."""

    def __init__(
        self,
        group: str,
        handlers: dict[str, Handler],
        settings: Settings,
        contract: Contract,
        store: ObjectStore,
        on_failure: FailureHandler | None = None,
    ):
        self.group = group
        self._dispatcher = Dispatcher(handlers, contract, store, on_failure)
        self._topics = sorted({TOPIC_FOR[event] for event in handlers})
        self._consumer = AIOKafkaConsumer(
            *self._topics,
            group_id=settings.kafka_group,
            enable_auto_commit=False,
            auto_offset_reset="earliest",
            value_deserializer=_decode,
            **connection_kwargs(settings),
        )
        self._task: asyncio.Task | None = None
        self.running = False

    async def start(self) -> None:
        await self._consumer.start()
        self._task = asyncio.create_task(self._run(), name=f"consumer-{self.group}")
        self.running = True
        log.info("consumer started", extra={"group": self.group, "topics": self._topics})

    async def stop(self) -> None:
        self.running = False
        if self._task:
            self._task.cancel()
            with contextlib.suppress(asyncio.CancelledError):
                await self._task
        await self._consumer.stop()

    async def _run(self) -> None:
        # Runs until stop(): no message or broker error ends it.
        while True:
            try:
                async for record in self._consumer:
                    await self._dispatcher.handle(record.topic, record.value)
                    try:
                        await self._consumer.commit()
                    except Exception:
                        log.warning("commit failed; the message may be redelivered",
                                    extra={"topic": record.topic, "offset": record.offset})
                return
            except Exception:
                log.exception("consumer error; resuming", extra={"group": self.group})
                await asyncio.sleep(BACKOFF_SECONDS)
