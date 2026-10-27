# Apparule commerce (`api/commerce`)

Money decisions and notification delivery (Python, port 8083;
docs/system-design.md §4, S-6, S-7). No public ingress: HTTP serves only
`/health` and `/ready`, and the work arrives over Kafka on the shared bus's
`cuelabs.requests` lane (consumer group `apparule-commerce`). It keeps no
store: everything a decision needs travels in the message, and every
decision goes back to `common` as `apparule.payments.outcome` with the
balanced ledger lines to append.

| Event in | Decision out |
| --- | --- |
| `payments.provider_event` | `charge.success` settles the order when the reference names a still-quoted order and the amount and currency match its quote exactly (`charge_settled`, 10 % fee); otherwise `charge_rejected` with a reason. Failed transfers and refunds become `payout_failed` / `refund_failed`. |
| `orders.transition` | `delivered`: Paystack transfer of quote − fee to the designer's recipient (`payout_released`). `refunded`: full refund (`refund_issued`). References derive from the order, so a redelivery never pays twice. |
| `payouts.recipient_requested` | Resolve the account name, check it against the designer's name, create the transfer recipient (`recipient_verified` / `recipient_failed`). |
| `ledger.reconcile_requested` | Compare the window's ledger movements with Paystack's transactions, transfers and refunds; each disagreement is a `mismatch` for a human (§6.4). |
| `notifications.created` | FCM push (silent for capture results), Brevo email for money events, social pushes coalesced over 5 minutes. Best-effort. |

Outcome ids are uuid5 of the decision's source, so `common` stores each
decision once. Paystack outages retry three times, then become a `*_failed`
outcome rather than a stuck consumer. Without `PAYSTACK_SECRET_KEY` the
service runs notify-only (self-host without payments, §10.2).

## Layout

```
app/main.py           FastAPI + lifespan: consumer, producer, clients
app/config.py         env config (fee in basis points, delivery keys)
payments/             settle (provider events), movements (payouts, refunds), ids, fee
payouts/              bank-account verification
reconcile/            the hourly comparison
notify/               notifier (coalescing), fcm, brevo
paystack/             the Paystack API client
kafka/ storage/ contract/ health/ telemetry/   shared service plumbing
tests/                pytest suite (Paystack mocked)
```

## Run

From the repo root (recommended): `make up`. Natively:

```bash
cp .env.example .env
pip install -r requirements-dev.txt
uvicorn app.main:app --port 8083
```

## Test

```bash
pytest && ruff check .
```
