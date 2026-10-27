"""Money decisions (S-6, system-design.md §6.3): does a charge settle an
order, what a payout is, and executing transfers and refunds. Every
decision goes back to common as an apparule.payments.outcome with the
ledger lines to append; common stores it as made."""

import uuid

# Outcome ids are uuid5 of the decision's source, so the same decision made
# twice (a redelivered message) carries the same id and is stored once.
NAMESPACE = uuid.UUID("6f1c3a2e-9b4d-4e8f-a1c7-3d5b2e9f0a41")


def outcome_id(kind: str, source: str) -> str:
    return str(uuid.uuid5(NAMESPACE, f"{kind}:{source}"))


def money(amount: int, currency: str) -> dict:
    return {"amount": amount, "currency": currency}


def platform_fee(quote: int, bps: int) -> int:
    """A-1: the fee is a share of the quote, rounded to the kobo."""
    return (quote * bps + 5_000) // 10_000
