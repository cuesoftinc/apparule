"""apparule.payments.provider_event -> a decision about a Paystack event.

charge.success settles an order when the reference names an order that is
still quoted and the amount and currency match what its checkout was started
for (the payment row, never the current quote); the money moves into escrow.
Anything else is rejected with a reason for a human.
Transfer and refund webhooks confirm or fail what commerce started.
"""

from payments import money, outcome_id, platform_fee


def decide(msg: dict, fee_bps: int) -> dict | None:
    event = msg["event"]
    data = msg["payload"]
    source = msg["provider_event_id"]
    base = {"provider_event_id": source}
    if event == "charge.success":
        return _charge(msg, data, base, fee_bps)
    if event in ("transfer.failed", "transfer.reversed"):
        request_id = _request_from_reference(data.get("reference", ""))
        out = {
            **base,
            "outcome_id": outcome_id("payout_failed", source),
            "kind": "payout_failed",
            "reference": str(data.get("reference", "")),
            "provider_ref": str(data.get("transfer_code", "")),
            "reason": "provider_error",
        }
        if request_id:
            out["request_id"] = request_id
        return out
    if event == "refund.failed":
        return {**base, "outcome_id": outcome_id("refund_failed", source), "kind": "refund_failed", "reason": "provider_error", "provider_ref": str(data.get("id", ""))}
    # charge.dispute.*, transfer.success, refund.processed: informational;
    # the provider event is stored, and reconciliation covers the money.
    return None


def _charge(msg: dict, data: dict, base: dict, fee_bps: int) -> dict:
    source = msg["provider_event_id"]
    order = msg.get("order")
    reference = str(data.get("reference", ""))
    # Paystack assigns the same immutable transaction id to its verification
    # response and eventual webhook. Using it makes both ingress paths converge
    # on one durable payment outcome.
    transaction_id = data.get("id")
    valid_transaction_id = (
        isinstance(transaction_id, int)
        and not isinstance(transaction_id, bool)
        and 0 < transaction_id <= 9_223_372_036_854_775_807
    )
    outcome_source = str(transaction_id) if valid_transaction_id else source

    def reject(reason: str) -> dict:
        out = {
            **base,
            "outcome_id": outcome_id("charge_rejected", outcome_source),
            "kind": "charge_rejected",
            "reference": reference,
            "reason": reason,
        }
        if order:
            out["request_id"] = order["request_id"]
        return out

    if not reference.startswith("apr_"):
        return reject("unknown_reference")
    if data.get("status") != "success":
        return reject("provider_error")
    if not valid_transaction_id:
        return reject("invalid_transaction_id")
    if not order:
        return reject("unknown_reference")
    if order.get("reference") != reference:
        return reject("unknown_reference")
    if order["status"] != "quoted":
        return reject("order_not_payable")
    # The amount the checkout was started for; the quote may differ since.
    expected = order.get("payment")
    if not expected:
        return reject("unknown_reference")
    if data.get("currency") != expected["currency"]:
        return reject("currency_mismatch")
    amount = data.get("amount")
    if not isinstance(amount, int) or isinstance(amount, bool):
        return reject("amount_mismatch")
    if amount != expected["amount"]:
        return reject("amount_mismatch")
    currency = expected["currency"]
    fee = platform_fee(amount, fee_bps)
    return {
        **base,
        "outcome_id": outcome_id("charge_settled", outcome_source),
        "kind": "charge_settled",
        "request_id": order["request_id"],
        "reference": reference,
        "provider_ref": str(transaction_id),
        "amount": money(amount, currency),
        "fee": money(fee, currency),
        "ledger": [{"account": "escrow", "amount": amount}, {"account": "customer_funds", "amount": -amount}],
    }


def _request_from_reference(reference: str) -> str | None:
    """Payout references are po_<request id hex>; see movements.payout_reference."""
    if reference.startswith("po_") and len(reference) == 35:
        h = reference[3:]
        return f"{h[:8]}-{h[8:12]}-{h[12:16]}-{h[16:20]}-{h[20:]}"
    return None
