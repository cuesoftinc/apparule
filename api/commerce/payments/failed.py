"""The failed outcome for a request commerce kept failing on
(shared-messaging.md rule 10): common records it for a human instead of
waiting. Events that ask for no money decision have none; the consumer logs
them and moves on."""

from kafka import topics
from payments import outcome_id

REASON = "processing_failed"


def failed_outcome(event: str, msg: dict) -> dict | None:
    if event == topics.PROVIDER_EVENT and msg.get("event") == "charge.success":
        source = msg["provider_event_id"]
        out = {
            "provider_event_id": source,
            "outcome_id": outcome_id("charge_rejected", source),
            "kind": "charge_rejected",
            "reference": str(msg.get("payload", {}).get("reference", "")),
            "reason": REASON,
        }
        if msg.get("order"):
            out["request_id"] = msg["order"]["request_id"]
        return out
    if event == topics.ORDERS_TRANSITION and msg["to"] in ("delivered", "refunded"):
        kind = "payout_failed" if msg["to"] == "delivered" else "refund_failed"
        return {"outcome_id": outcome_id(kind, msg["transition_id"]), "kind": kind, "request_id": msg["request_id"], "transition_id": msg["transition_id"], "reason": REASON}
    if event == topics.RECIPIENT_REQUESTED:
        # provider_error is the reason the payout-account screen explains.
        return {
            "outcome_id": outcome_id("recipient_failed", msg["attempt_id"]),
            "kind": "recipient_failed",
            "designer_id": msg["designer_id"],
            "attempt_id": msg["attempt_id"],
            "reason": "provider_error",
        }
    return None
