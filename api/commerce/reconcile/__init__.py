"""apparule.ledger.reconcile_requested -> mismatches for a human (§6.4).

The window's ledger movements (from common) are compared with Paystack's
successful transactions, transfers and refunds by reference. Paystack dates
an item by its own clock and the ledger by when the outcome arrived, so both
sides are searched over `lookup` (the window widened on both sides), and only
items inside the window whose reference is missing from the other side are
reported. Every disagreement becomes a payments.outcome of kind mismatch;
commerce never "fixes" the ledger itself.
"""

from datetime import UTC, datetime

from payments import money, outcome_id
from paystack import Paystack


async def compare(paystack: Paystack, msg: dict) -> list[dict]:
    start, end = msg["window"]["from"], msg["window"]["to"]
    lookup = msg.get("lookup") or msg["window"]
    window = (_parse(start), _parse(end))
    # Primary id -> (kind, amount, currency, created); references alias ids.
    provider: dict[str, tuple[str, int, str, datetime | None]] = {}
    aliases: dict[str, str] = {}
    for t in await paystack.transactions(lookup["from"], lookup["to"]):
        key = str(t.get("id"))
        provider[key] = ("charge", int(t.get("amount", 0)), str(t.get("currency", "NGN")), _created(t))
        aliases[str(t.get("reference"))] = key
    for t in await paystack.transfers(lookup["from"], lookup["to"]):
        key = str(t.get("transfer_code"))
        provider[key] = ("payout", int(t.get("amount", 0)), str(t.get("currency", "NGN")), _created(t))
        aliases[str(t.get("reference"))] = key
    for r in await paystack.refunds(lookup["from"], lookup["to"]):
        provider[str(r.get("id"))] = ("refund", int(r.get("amount", 0)), str(r.get("currency", "NGN")), _created(r))

    out: list[dict] = []
    seen: set[str] = set()
    label = f"{start}/{end}"
    for m in msg["movements"]:
        ref, amount = m["reference"], m["amount"]
        key = ref if ref in provider else aliases.get(ref)
        if key is not None:
            seen.add(key)
        if not _inside(_parse(m["at"]) if "at" in m else None, window):
            continue  # matched for the other side only; its own window reports it
        if key is None:
            out.append(_mismatch(label, m, "missing_in_provider"))
        elif provider[key][1] != amount["amount"] or provider[key][2] != amount["currency"]:
            out.append(_mismatch(label, m, "amount_mismatch"))
    # Paystack money the ledger never recorded.
    for key in sorted(provider.keys() - seen):
        kind, amount, currency, created = provider[key]
        if not _inside(created, window):
            continue
        out.append(
            {
                "outcome_id": outcome_id("mismatch", f"{label}:{key}"),
                "kind": "mismatch",
                "reference": key,
                "provider_ref": key,
                "amount": money(amount, currency),
                "reason": "missing_in_ledger",
            }
        )
    return out


def _parse(value: str) -> datetime:
    at = datetime.fromisoformat(value)
    return at if at.tzinfo else at.replace(tzinfo=UTC)


def _created(item: dict) -> datetime | None:
    value = item.get("createdAt") or item.get("created_at")
    try:
        return _parse(str(value)) if value else None
    except ValueError:
        return None


def _inside(at: datetime | None, window: tuple[datetime, datetime]) -> bool:
    """An item without a time is judged in every window it is found in."""
    return at is None or window[0] <= at < window[1]


def _mismatch(window: str, m: dict, reason: str) -> dict:
    return {
        "outcome_id": outcome_id("mismatch", f"{window}:{m['reference']}"),
        "kind": "mismatch",
        "request_id": m["request_id"],
        "reference": m["reference"],
        "amount": m["amount"],
        "reason": reason,
    }
