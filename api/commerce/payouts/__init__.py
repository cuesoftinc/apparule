"""apparule.payouts.recipient_requested -> a verified transfer recipient
(pages.md B8). commerce resolves the account name with Paystack, checks it
against the designer's name, and creates the recipient payouts go to."""

import re

from payments import outcome_id
from paystack import Paystack, PaystackError, PaystackUnavailable

BANK_NAMES = {"058": "GTBank", "044": "Access Bank", "057": "Zenith Bank", "011": "First Bank", "033": "UBA"}


def names_match(resolved: str, holder: str) -> bool:
    """At least two shared name tokens, or all of a one-word name: banks
    order names differently and add middle names."""
    def tokens(s: str) -> set[str]:
        return {t for t in re.split(r"[^a-z]+", s.lower()) if len(t) > 1}

    a, b = tokens(resolved), tokens(holder)
    shared = a & b
    return len(shared) >= 2 or (len(b) == 1 and shared == b)


async def verify(paystack: Paystack, msg: dict) -> dict:
    designer, attempt = msg["designer_id"], msg["attempt_id"]
    base = {"designer_id": designer, "attempt_id": attempt}

    def failed(reason: str) -> dict:
        return {**base, "outcome_id": outcome_id("recipient_failed", attempt), "kind": "recipient_failed", "reason": reason}

    try:
        resolved = await paystack.resolve_account(msg["account_number"], msg["bank_code"])
    except PaystackError:
        return failed("account_invalid")
    except PaystackUnavailable:
        return failed("provider_error")
    name = str(resolved.get("account_name", ""))
    if not names_match(name, msg["account_holder"]):
        return failed("name_mismatch")
    try:
        recipient = await paystack.create_recipient(name, msg["account_number"], msg["bank_code"])
    except PaystackError:
        return failed("account_invalid")
    except PaystackUnavailable:
        return failed("provider_error")
    return {**base, "outcome_id": outcome_id("recipient_verified", attempt), "kind": "recipient_verified",
            "recipient": {"recipient_code": recipient["recipient_code"], "account_name": name,
                          "bank_name": BANK_NAMES.get(msg["bank_code"], msg["bank_code"]),
                          "last4": msg["account_number"][-4:]}}
