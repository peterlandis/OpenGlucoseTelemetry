# OGT local contracts (MVP)

OGT defines **ingestion** shapes here. Canonical event semantics and JSON Schema for `glucose.reading` are owned by **OGIS**; this repo pins a copy under `pinned/` for CI (see `pinned/PIN.md`).

## Ingestion envelope

Adapters submit a single JSON object:

| Field | Type | Purpose |
|-------|------|--------|
| `source` | string | Adapter channel id (`healthkit`, `mock`, `dexcom`, …). |
| `payload` | object | Source-specific JSON; validated per `source`. |
| `received_at` | string (`date-time`) | When OGT received the submission (RFC 3339). |
| `trace_id` | string | Correlation id for logs and tests. |
| `adapter` | object | `id` and semver `version` for provenance. |

**Schema:** [`ingestion-envelope.schema.json`](./ingestion-envelope.schema.json)

### Example

```json
{
  "source": "healthkit",
  "payload": {},
  "received_at": "2026-03-29T12:00:00.000Z",
  "trace_id": "550e8400-e29b-41d4-a716-446655440000",
  "adapter": {
    "id": "ogt.adapter.healthkit",
    "version": "0.1.0"
  }
}
```

## Adapter payloads

| `source` | Schema |
|----------|--------|
| `healthkit` | [`healthkit-payload.schema.json`](./healthkit-payload.schema.json) |
| `mock` | [`mock-payload.schema.json`](./mock-payload.schema.json) |
| `dexcom` | [`dexcom-payload.schema.json`](./dexcom-payload.schema.json) |

**Dexcom:** The Dexcom payload schema is **OGT’s** contract for tests and adapters (see `description` inside the file). It is **not** published or endorsed by Dexcom as their API schema. For authoritative Dexcom cloud APIs (OAuth, endpoints, response shapes), use **[Dexcom Developer documentation](https://developer.dexcom.com/docs/)** and implement a mapper from API responses into this payload (or evolve the schema with a version bump).

## Pinned OGIS schema

- [`pinned/glucose.reading.v0_1.json`](./pinned/glucose.reading.v0_1.json) — canonical output validation.
- [`pinned/PIN.md`](./pinned/PIN.md) — provenance and update procedure.
