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
import time
from collections.abc import Awaitable, Callable

from aiokafka import AIOKafkaConsumer, TopicPartition

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
# drain waits this long for a record before it looks at the lag again.
IDLE_SECONDS = 1.0


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
                log.warning("handler failed; retrying", extra={"topic": topic, "event": event, "request_id": request_id, "attempt": attempt, "error": type(error).__name__})
                await asyncio.sleep(self._backoff * 2 ** (attempt - 1))
        log.error("handler kept failing; recorded and skipped", exc_info=error, extra={"topic": topic, "event": event, "request_id": request_id, "attempts": self._attempts})
        if self._on_failure is not None and data is not None:
            try:
                await self._on_failure(event, data, request_id)
            except Exception:
                log.exception("recording the failure failed", extra={"event": event, "request_id": request_id})


class Consumer:
    """`handlers` maps each event this pool handles to its handler;
    `on_failure` answers a request whose handler kept failing.

    Where CPU is always allocated (compose, Helm) `background` runs a loop
    that consumes between requests. On request-based CPU (S-14) nothing runs
    between requests: drain() consumes inside the settle request instead."""

    def __init__(
        self,
        group: str,
        handlers: dict[str, Handler],
        settings: Settings,
        contract: Contract,
        store: ObjectStore,
        on_failure: FailureHandler | None = None,
        background: bool = True,
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
        self._background = background
        self._lock = asyncio.Lock()
        self._task: asyncio.Task | None = None
        self.running = False

    async def start(self) -> None:
        await self._consumer.start()
        if self._background:
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

    async def caught_up(self) -> bool:
        """Whether the group has committed every message now on its topics,
        across all partitions and whichever instance holds them."""
        partitions = []
        for topic in self._topics:
            ids = self._consumer.partitions_for_topic(topic)
            if not ids:
                return False  # metadata not fetched yet: still joining
            partitions += [TopicPartition(topic, p) for p in ids]
        ends = await self._consumer.end_offsets(partitions)
        firsts = await self._consumer.beginning_offsets(partitions)
        for tp in partitions:
            committed = await self._consumer.committed(tp)
            if committed is None:
                committed = firsts[tp]  # never committed: the group starts at the first offset
            if committed < ends[tp]:
                return False
        return True

    async def _is_caught_up(self) -> bool:
        try:
            return await self.caught_up()
        except Exception as exc:
            log.warning("lag check failed", extra={"group": self.group, "error": type(exc).__name__})
            return False

    async def wait_caught_up(self, budget: float) -> bool:
        """Polls caught_up until it holds or budget seconds pass."""
        deadline = time.monotonic() + budget
        while True:
            if await self._is_caught_up():
                return True
            if time.monotonic() >= deadline:
                return False
            await asyncio.sleep(0.25)

    async def drain(self, budget: float) -> bool:
        """Handles what is waiting, inside the caller's request, until the
        group has committed everything or budget seconds pass; answers
        whether it caught up. While the background loop consumes, only
        waits for it."""
        deadline = time.monotonic() + budget
        if self._task is not None:
            return await self.wait_caught_up(budget)
        async with self._lock:
            while True:
                if await self._is_caught_up():
                    return True
                left = deadline - time.monotonic()
                if left <= 0:
                    return False
                # One record at a time: commit() then covers only what was handled.
                batches = await self._consumer.getmany(timeout_ms=int(min(left, IDLE_SECONDS) * 1000), max_records=1)
                for records in batches.values():
                    for record in records:
                        await self._dispatcher.handle(record.topic, record.value)
                        try:
                            await self._consumer.commit()
                        except Exception:
                            log.warning("commit failed; the message may be redelivered", extra={"topic": record.topic, "offset": record.offset})

    async def _run(self) -> None:
        # Runs until stop(): no message or broker error ends it.
        while True:
            try:
                async for record in self._consumer:
                    await self._dispatcher.handle(record.topic, record.value)
                    try:
                        await self._consumer.commit()
                    except Exception:
                        log.warning("commit failed; the message may be redelivered", extra={"topic": record.topic, "offset": record.offset})
                return
            except Exception:
                log.exception("consumer error; resuming", extra={"group": self.group})
                await asyncio.sleep(BACKOFF_SECONDS)
