# Apparule — Commission Order Lifecycle

> The full state machine behind SOC-004/005/006 (pages.md B3/C5/C8,
> data-model.md §5 `REQUEST`). **[Proposed]** — this is the contract the
> commerce phase implements; payments/escrow are the ratified A-1 model
> (Paystack + platform ledger, 10% fee).

## 1. State machine

```mermaid
stateDiagram-v2
    [*] --> requested : customer submits (snapshot frozen)
    requested --> quoted : designer quotes (price + due date)
    requested --> declined : designer declines (reason)
    requested --> cancelled : customer withdraws
    quoted --> paid : customer pays (escrow hold)
    quoted --> cancelled : customer rejects quote / quote expires (7d)
    paid --> in_progress : designer starts work
    paid --> refunded : system, designer inactive T+14d (no start)
    in_progress --> shipped : designer ships (tracking optional)
    shipped --> delivered : customer confirms OR auto-confirm T+14d
    delivered --> [*] : payout released
    paid --> disputed : either party (before delivery confirm)
    in_progress --> disputed
    shipped --> disputed
    disputed --> delivered : resolved for designer (payout releases)
    disputed --> refunded : resolved for customer
    refunded --> [*]
    declined --> [*]
    cancelled --> [*]
```

Rules:

- **Measurement snapshot freezes at `requested`** — later vault changes never
  mutate an order; a re-measure prompts a *new* request.
- **Quotes expire** after 7 days un-actioned (state → `cancelled`, both
  parties notified) **[Decided, A-7]**.
- **Auto-confirm**: `shipped` → `delivered` at T+14 days without customer
  action, after two reminders — protects designer payout from ghosting
  **[Decided, A-7]**.
- **Dispute window** ends at delivery confirmation; disputes freeze payout
  and open a support thread (routes to `clients.cuesoft.io` when live).
- **Escrow never waits forever [Decided]**: `paid` with no `in_progress`
  within **14 days** auto-refunds (system transition; designer notified +
  strike recorded); an order past `due_at + 14 days` without `shipped`
  surfaces a one-click "request refund" dispute path to the customer with
  reminders to the designer at due_at and due_at+7.
- Cancellation after `paid` is a refund path, not a `cancelled` transition —
  money movements only ever resolve through `delivered` (payout) or
  `refunded`.

## 2. Permissions matrix

| Action | Customer | Designer | System |
| --- | --- | --- | --- |
| submit request | ✓ (with owned snapshot) | — | — |
| quote / decline | — | ✓ | quote expiry |
| pay | ✓ | — | — |
| start / ship | — | ✓ | — |
| confirm delivery | ✓ | — | auto-confirm T+14 |
| open dispute | ✓ | ✓ | — |
| resolve dispute | — | — | support/admin only |
| view snapshot values | ✓ (own) | ✓ (this order only) | — |

The snapshot-visibility rule is the privacy core: a designer sees a
customer's measurements **only inside an order that customer initiated**,
and only that frozen copy.

## 3. Money movement (escrow model, provider-gated)

| Event | Movement |
| --- | --- |
| `paid` | full quote captured to platform escrow; `PAYMENT.state = held` |
| `delivered` | payout = quote − platform fee → designer payout account; `released` |
| `refunded` | platform triggers the Paystack refund from the ledger within **1 business day** of the resolving event; full-amount refunds only in v1 (no partials); the platform absorbs provider refund fees **[Decided]** |

Platform fee: **10% of quote** (A-1, ratified); payout timing: **on delivery
confirmation** — no instant payout in v1 (A-1). Provider: Paystack for NG
rails; Stripe arrives with international (A-1). All amounts carry `currency`
(NGN-only v1, data-model §5). Designer payouts require completed KYC
(`DESIGNER_PROFILE.payout_account` verified) *before* their posts can accept
requests — not at payout time, when it's too late.

## 4. Notifications map (SOC-008)

| Transition | Customer | Designer |
| --- | --- | --- |
| requested | receipt confirmation | **push + badge: new request** |
| quoted | **push: quote received** (+T-2d expiry reminder) | — |
| paid | payment receipt | **push: order funded — start work** |
| in_progress | status update | — |
| shipped | **push: shipped** (+tracking) | — |
| auto-confirm reminders (T+7, T+12 after shipped) | reminder ×2 | — |
| delivered | confirmation + review prompt **[Later]** | **push: payout released** |
| declined / cancelled / disputed / refunded | push | push |

All notifications also land in the in-app activity sheet (pages.md C10);
email mirrors only money events (paid, payout, refund) **[Proposed]**.

## 5. Thread messaging scope

Each request carries one message thread (SOC-005), open from `requested`
until 30 days after terminal state. Attachments: images only (reference
photos, progress shots). No payment links in threads (anti-fee-evasion +
safety); the pay CTA is only ever the order's own payment box. Full DMs
outside orders remain out of scope (SOC-010).
