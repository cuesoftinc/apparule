"""Events and lanes (system-design.md §5.3). Schemas for each event live in
api/common/contract.

An event names the envelope's `type` and its schema. Topics are the three
lanes of the CueLABS shared message bus (the delivery standard's
shared-messaging.md): every product reads and writes them, so a consumer
reads the type first and skips whatever isn't one of its own events.
"""

# Events commerce handles.
ORDERS_TRANSITION = "apparule.orders.transition"
PROVIDER_EVENT = "apparule.payments.provider_event"
RECIPIENT_REQUESTED = "apparule.payouts.recipient_requested"
RECONCILE_REQUESTED = "apparule.ledger.reconcile_requested"
NOTIFICATION_CREATED = "apparule.notifications.created"

# The event commerce sends.
PAYMENTS_OUTCOME = "apparule.payments.outcome"

# Topics: the shared bus's lanes.
TOPIC_UPLOADS = "cuelabs.uploads"
TOPIC_REQUESTS = "cuelabs.requests"
TOPIC_RESULTS = "cuelabs.results"

TOPIC_FOR = {
    ORDERS_TRANSITION: TOPIC_REQUESTS,
    PROVIDER_EVENT: TOPIC_REQUESTS,
    RECIPIENT_REQUESTED: TOPIC_REQUESTS,
    RECONCILE_REQUESTED: TOPIC_REQUESTS,
    NOTIFICATION_CREATED: TOPIC_REQUESTS,
    PAYMENTS_OUTCOME: TOPIC_RESULTS,
}
