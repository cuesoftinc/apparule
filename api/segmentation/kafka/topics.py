"""Events and lanes (system-design.md §5.3). Schemas for each event live in
api/common/contract.

An event names the envelope's `type` and its schema. Topics are the three
lanes of the CueLABS shared message bus (the delivery standard's
shared-messaging.md): every product reads and writes them, so a consumer
reads the type first and skips whatever isn't one of its own events.
"""

# Events segmentation handles or sends.
CAPTURE_READY = "apparule.capture.ready"
CAPTURE_MEASURED = "apparule.capture.measured"

# Topics: the shared bus's lanes.
TOPIC_UPLOADS = "cuelabs.uploads"
TOPIC_REQUESTS = "cuelabs.requests"
TOPIC_RESULTS = "cuelabs.results"

TOPIC_FOR = {
    CAPTURE_READY: TOPIC_REQUESTS,
    CAPTURE_MEASURED: TOPIC_RESULTS,
}
