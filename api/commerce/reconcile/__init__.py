"""apparule.ledger.reconcile_requested -> mismatches for a human (§6.4).

The window's ledger movements (from common) are compared with Paystack's
successful transactions, transfers and refunds for the same window. Every
disagreement becomes a payments.outcome of kind mismatch; commerce never
"fixes" the ledger itself.
"""

from payments import money, outcome_id
from paystack import Paystack


async def compare(paystack: Paystack, msg: dict) -> list[dict]:
    start, end = msg["window"]["from"], msg["window"]["to"]
    provider: dict[str, tuple[str, int, str]] = {}
    for t in await paystack.transactions(start, end):
        provider[str(t.get("id"))] = ("charge", int(t.get("amount", 0)), str(t.get("currency", "NGN")))
        provider.setdefault(str(t.get("reference")), provider[str(t.get("id"))])
    for t in await paystack.transfers(start, end):
        provider[str(t.get("transfer_code"))] = ("payout", int(t.get("amount", 0)), str(t.get("currency", "NGN")))
        provider.setdefault(str(t.get("reference")), provider[str(t.get("transfer_code"))])
    for r in await paystack.refunds(start, end):
        provider[str(r.get("id"))] = ("refund", int(r.get("amount", 0)), str(r.get("currency", "NGN")))

    out: list[dict] = []
    seen: set[str] = set()
    window = f"{start}/{end}"
    for m in msg["movements"]:
        ref, amount = m["reference"], m["amount"]
        seen.add(ref)
        found = provider.get(ref)
        if found is None:
            out.append(_mismatch(window, m, "missing_in_provider"))
        elif found[1] != amount["amount"] or found[2] != amount["currency"]:
            out.append(_mismatch(window, m, "amount_mismatch"))
    # Paystack money the ledger never recorded (by primary id only).
    keys = {k for k, v in provider.items() if k.isdigit() or k.startswith("TRF_")}
    for key in sorted(keys - seen):
        kind, amount, currency = provider[key]
        out.append({"outcome_id": outcome_id("mismatch", f"{window}:{key}"), "kind": "mismatch", "reference": key,
                    "provider_ref": key, "amount": money(amount, currency), "reason": "missing_in_ledger"})
    return out


def _mismatch(window: str, m: dict, reason: str) -> dict:
    return {"outcome_id": outcome_id("mismatch", f"{window}:{m['reference']}"), "kind": "mismatch", "request_id": m["request_id"],
            "reference": m["reference"], "amount": m["amount"], "reason": reason}
