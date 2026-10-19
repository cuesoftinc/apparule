# Kafka message contract

JSON Schemas (draft 2020-12) for every message between Apparule's services
(system-design.md §5.3). Each service validates what it produces and what it
consumes against these files.

`api/common` owns them because it owns the data. The other services get them
at build time: their images are built from the repository root and copy
`api/common/contract/*.schema.json` in (see each service's Dockerfile).

## Envelope

Every message is an [envelope](envelope.schema.json):

```json
{
  "type": "apparule.capture.ready",
  "version": 1,
  "id": "6f1c…",
  "produced_at": "2026-10-19T10:00:00Z",
  "data_ref": { "bucket": "…", "key": "apparule/stg/compute/6f1c….json" }
}
```

Apparule's events ride the three lanes of the CueLABS shared message bus
(decisions.md X-11; the rules are in the CueLABS delivery standard's
`shared-messaging.md`), which Expendit and Upstat read too. So every producer
writes the payload to `apparule/<env>/compute/<id>.json` and sends `data_ref`;
storage permissions keep Apparule's data to itself. `data` inline is accepted
by the schema for fixtures and tests only. Consumers read `type` first and
skip, without validating, anything that isn't an Apparule event they handle.

## Events and lanes

| Event (schema) | Lane | Key | Producer → consumer |
| --- | --- | --- | --- |
| [capture.uploaded](capture.uploaded.schema.json) | `cuelabs.uploads` | session id | uploads → common |
| [media.uploaded](media.uploaded.schema.json) | `cuelabs.uploads` | target id | uploads → common |
| [capture.ready](capture.ready.schema.json) | `cuelabs.requests` | session id | common (outbox) → segmentation |
| [orders.transition](orders.transition.schema.json) | `cuelabs.requests` | request id | common (outbox) → commerce |
| [payments.provider_event](payments.provider_event.schema.json) | `cuelabs.requests` | provider event id | common (outbox) → commerce |
| [payouts.recipient_requested](payouts.recipient_requested.schema.json) | `cuelabs.requests` | designer id | common (outbox) → commerce |
| [ledger.reconcile_requested](ledger.reconcile_requested.schema.json) | `cuelabs.requests` | `reconcile` | common's hourly job → commerce |
| [notifications.created](notifications.created.schema.json) | `cuelabs.requests` | account id | common (outbox) → commerce |
| [capture.measured](capture.measured.schema.json) | `cuelabs.results` | session id | segmentation → common |
| [payments.outcome](payments.outcome.schema.json) | `cuelabs.results` | request / designer id | commerce → common |

There are no compacted topics (X-11): the measurement template travels inside
`capture.ready`, and the ledger slice to reconcile inside
`ledger.reconcile_requested`. Apparule sends no heartbeat; Expendit is the
bus's keep-alive owner.

Shared types (ids, poses, QC codes, money, object refs, ledger lines) are in
[defs.schema.json](defs.schema.json). Money is always an integer in minor
units (kobo) with its currency.

The upload ticket the gateway verifies is specified in
[upload-ticket.md](upload-ticket.md).

## Changing a schema

1. Additive change (new optional field): edit the schema, keep `version`.
2. Breaking change: bump the envelope `version` the producer sends, and make
   the consumer accept both versions until every producer is upgraded.
3. Update the matching example in `examples/`. Every service's tests validate
   the examples, so a schema and its consumers can't drift silently.
