"""apparule.orders.transition -> payouts and refunds (§6.3).

`delivered` releases the payout (quote - fee) to the designer's transfer
recipient; `refunded` refunds the whole charge (order-lifecycle.md §3: full
refunds only, the platform absorbs the fee). Other transitions need no money.
Every Paystack call is idempotent by a reference derived from the order, so
a redelivered transition never pays twice.
"""

import logging

from payments import money, outcome_id, platform_fee
from paystack import Paystack, PaystackError, PaystackUnavailable

log = logging.getLogger(__name__)


def payout_reference(request_id: str) -> str:
    return "po_" + request_id.replace("-", "")


class Movements:
    def __init__(self, paystack: Paystack, fee_bps: int):
        self._paystack = paystack
        self._fee_bps = fee_bps

    async def on_transition(self, msg: dict) -> dict | None:
        if msg["to"] == "delivered":
            return await self._payout(msg)
        if msg["to"] == "refunded":
            return await self._refund(msg)
        return None

    async def _payout(self, msg: dict) -> dict | None:
        request_id, source = msg["request_id"], msg["transition_id"]
        payment = msg.get("payment")
        if not payment:
            log.error("delivered order has no held payment", extra={"request_id": request_id})
            return None
        amount = payment["amount"]["amount"]
        currency = payment["amount"]["currency"]
        fee = platform_fee(amount, self._fee_bps)
        payout = amount - fee

        def failed(reason: str) -> dict:
            return {"outcome_id": outcome_id("payout_failed", source), "kind": "payout_failed", "request_id": request_id,
                    "transition_id": source, "reason": reason}

        recipient = msg.get("payout_recipient")
        if not recipient:
            return failed("no_recipient")
        try:
            transfer = await self._paystack.transfer(payout, recipient["recipient_code"], payout_reference(request_id),
                                                     "Apparule payout")
        except PaystackError as exc:
            # A duplicate reference means this payout already went out.
            if "duplicate" not in str(exc).lower():
                return failed("provider_refused")
            transfer = {"transfer_code": payout_reference(request_id)}
        except PaystackUnavailable:
            return failed("provider_error")
        return {"outcome_id": outcome_id("payout_released", source), "kind": "payout_released", "request_id": request_id,
                "transition_id": source, "reference": payout_reference(request_id),
                "provider_ref": str(transfer.get("transfer_code", "")),
                "amount": money(payout, currency), "fee": money(fee, currency),
                "ledger": [{"account": "escrow", "amount": -amount}, {"account": "designer_payable", "amount": payout},
                           {"account": "platform_fee", "amount": fee}]}

    async def _refund(self, msg: dict) -> dict | None:
        request_id, source = msg["request_id"], msg["transition_id"]
        payment = msg.get("payment")
        if not payment:
            return None  # refunded before any charge settled: no money moved
        amount = payment["amount"]["amount"]
        currency = payment["amount"]["currency"]
        transaction = payment.get("provider_transaction_id") or payment["reference"]
        try:
            refund = await self._paystack.refund(transaction, amount)
        except PaystackError as exc:
            if "fully reversed" not in str(exc).lower() and "already" not in str(exc).lower():
                return {"outcome_id": outcome_id("refund_failed", source), "kind": "refund_failed", "request_id": request_id,
                        "transition_id": source, "reason": "provider_refused"}
            refund = {}
        except PaystackUnavailable:
            return {"outcome_id": outcome_id("refund_failed", source), "kind": "refund_failed", "request_id": request_id,
                    "transition_id": source, "reason": "provider_error"}
        return {"outcome_id": outcome_id("refund_issued", source), "kind": "refund_issued", "request_id": request_id,
                "transition_id": source, "reference": payment["reference"], "provider_ref": str(refund.get("id", "")),
                "amount": money(amount, currency),
                "ledger": [{"account": "escrow", "amount": -amount}, {"account": "refund", "amount": amount}]}
