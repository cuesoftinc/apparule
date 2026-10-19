# Upload ticket (S-15)

`api/common` authorizes an upload before any bytes move: consent, ownership,
account state, rate limits and the 100 MB/day quota (system-design.md §6.1,
§8). It then issues a ticket that `api/uploads` verifies with a public key and
no call back. The gateway never holds a key that can mint tickets.

## Format

```
v1.<claims>.<signature>
```

- `claims` is base64url (no padding) of the UTF-8 JSON below.
- `signature` is base64url (no padding) of the Ed25519 signature over the
  ASCII bytes `v1.<claims>`.

```json
{
  "kid": "2026-10",
  "jti": "8f14e45f-ceea-4e67-a6f8-6b2c1d3e4f50",
  "account_id": "1e2d3c4b-…",
  "target": { "kind": "capture", "id": "5c2a9d1e-…" },
  "poses": ["front", "side"],
  "max_files": 2,
  "max_bytes": 10485760,
  "iat": 1792404000,
  "exp": 1792404300
}
```

| Claim | Meaning |
| --- | --- |
| `kid` | Which signing key; lets keys rotate without downtime. |
| `jti` | Ticket id. Single use: `common` records it as used when it consumes the upload event, and ignores a second upload under the same id. |
| `account_id` | The account the upload belongs to. |
| `target` | `capture` (a measurement session), `post_media` (a designer's media batch) or `attachment` (an order thread), and its id. The target exists before the ticket is issued. |
| `poses` | Captures only: the poses this ticket accepts. A first upload allows `front` and `side`; a retake ticket (`POST /sessions/{id}/poses/{pose}/ticket`) allows one. |
| `max_files` | How many images the request may carry (2 for a capture, 1 for a retake or an attachment, up to 10 for post media). |
| `max_bytes` | The size cap per image (10 MB). |
| `iat`, `exp` | Unix seconds. Tickets live 5 minutes. Verifiers allow 30 s of clock skew. |

## Keys

- `api/common` holds `UPLOAD_TICKET_PRIVATE_KEY` as `kid:<base64url 32-byte
  Ed25519 seed>`.
- `api/uploads` holds `UPLOAD_TICKET_PUBLIC_KEYS` as a comma-separated list of
  `kid:<base64url 32-byte public key>`, so the old key keeps verifying while a
  new one rolls out. Rotation publishes the new public key first, keeps both
  for one ticket lifetime, then retires the old one (§8).
- `go run ./cmd/ticketkey` in `api/common` generates a pair.

## The request

`POST /api/v1/uploads`, `multipart/form-data`, header `Upload-Ticket`.

- Captures: fields `image_front` and/or `image_side`, exactly the ticket's
  `poses`.
- Post media and attachments: one or more `images` fields, at most
  `max_files`.

Success is `202 {"target": {kind, id}, "status": "processing"}` for a capture,
`202 {"target": {kind, id}, "status": "received", "count": n}` otherwise.

## Gateway checks, in order

1. `Upload-Ticket` header present and well formed: else `401 invalid_ticket`.
2. Signature valid for a known `kid`: else `401 invalid_ticket`.
3. Not expired: else `401 ticket_expired`.
4. `Content-Length` within `max_files × max_bytes` plus multipart overhead,
   checked before the body is read: else `413 file_too_large`.
5. Fields match the ticket (the allowed poses, no more than `max_files`):
   else `422 validation_failed`.
6. Each file within `max_bytes`: else `413 file_too_large` (with `pose`).
7. Magic bytes are JPEG, PNG, WebP or HEIC: else `415 unsupported_type`
   (with `pose`).
8. The image decodes: else `422 undecodable_image` (with `pose`).

Then the gateway strips EXIF and GPS, re-encodes to JPEG at ≤ 2048 px on the
long edge, writes `apparule/<env>/tmp/<kind>/<target id>/<jti>/<field>.jpg`,
and publishes `capture.uploaded` or `media.uploaded`. While Kafka or storage
is away it answers `503 service_unavailable` with `Retry-After`.
