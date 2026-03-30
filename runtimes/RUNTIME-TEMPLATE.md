# OGT runtime template (all languages)

Every **language runtime** under `runtimes/<name>/` should follow the same **shape** as the TypeScript reference so contributors know where code belongs and how data flows.

## Required directories

| Directory | Responsibility |
|-----------|------------------|
| **`collectors/`** | Ingestion pipeline: validate envelope, validate per-source payload, route by `source`, invoke adapters, then normalize, semantic rules, optional dedupe, OGIS-shaped validation (same **stage order** as `runtimes/typescript/collectors/pipeline.ts` / Swift `OGTCollectorSubmit.run`). May include path helpers to repo `spec/`. |
| **`adapters/`** | One **subfolder per `source` id** (e.g. `healthkit/`, `dexcom/`, `mock/`). Each maps vendor **`payload`** JSON to **pre-normalize** `glucose.reading` v0.1 fields; the collector normalizes and validates afterward. |

Optional but common:

| Directory | Responsibility |
|-----------|----------------|
| **`dev/`** | CLI, fixture runners, local smoke scripts (see `runtimes/typescript/dev/`, `runtimes/swift/examples/`). |

---

## Pipeline layers (MVP — in order)

These are the **logical layers** every runtime should implement so behavior matches golden fixtures and the parity matrix.

| # | Layer | Responsibility |
|---|--------|------------------|
| **1** | **Ingress** | Accept ingestion **envelope** input (e.g. `unknown` / JSON parse in TS, `Data` decode in Swift). Wire shape: [`spec/ingestion-envelope.schema.json`](../spec/ingestion-envelope.schema.json) (`source`, `payload`, `received_at`, `trace_id`, `adapter`). |
| **2** | **Envelope validation** | Reject invalid envelopes before any adapter runs (empty `source`/`trace_id`, bad `received_at`, non-object `payload`, etc.). |
| **3** | **Payload validation** | For known `source`, enforce **allowed keys + required fields + enums** (per-source schema or hand-written rules). Unknown `source` → **`ADAPTER_UNKNOWN`** (no adapter call). |
| **4** | **Adapter map** | **`adapters/<source>/`**: map validated `payload` → **pre-normalize** canonical reading (OGIS field semantics; units/timestamps may still need normalization). |
| **5** | **Normalize** | Canonicalize timestamps (UTC, consistent fractional seconds), glucose to **mg/dL**, bound optional strings; fill `received_at` if absent from envelope. |
| **6** | **Semantic rules** | Policy after normalization (e.g. plausible glucose range, clock skew on `observed_at`, parseable optional timestamps). |
| **7** | **Dedupe (optional)** | In-memory or pluggable dedupe key (`subject_id` + `observed_at` + `raw_event_id`); duplicate → **`DUPLICATE_EVENT`**. |
| **8** | **OGIS validation** | Final check against pinned **`glucose.reading` v0.1** ([`spec/pinned/glucose.reading.v0_1.json`](../spec/pinned/glucose.reading.v0_1.json)) — Ajv in TS, equivalent rules in Swift. |
| **9** | **Result** | Success: normalized canonical reading. Failure: structured error (`code`, `message`, `trace_id`, optional `field`). |

**Data flow (one line):**

```text
Envelope → validate envelope → validate payload (by source) → adapter map → normalize → semantic → [dedupe] → OGIS check → result
```

---

## Data flow (diagram)

```text
Ingestion envelope JSON
  → collectors: validate envelope + validate payload + route by source
  → adapters/<source>: map payload → pre-canonical reading
  → collectors: normalize + semantic rules + optional dedupe + OGIS validation
  → canonical glucose.reading (v0.1)
```

---

## Contracts (repo root, shared)

- **`spec/`** — JSON Schemas (ingestion envelope, per-source **payload** schemas, pinned OGIS).
- **`examples/`** — golden **ingestion** + **canonical** JSON for cross-runtime tests ([`examples/canonical/README.md`](../examples/canonical/README.md)).

Implementations must stay aligned with [`specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md`](../specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md) (and future matrices for other languages) where applicable.

---

## Adding a **new provider** (`source`)

Use this when introducing a **new `source` id** (e.g. `abbott_libre`, `vendor_x`). MVP runtimes today implement `healthkit`, `dexcom`, and `mock`; the same pattern applies to any addition.

### 1. Contract and fixtures (repo root — language-agnostic)

| Step | What to add | Why |
|------|-------------|-----|
| **Stable `source` string** | Pick one id (lowercase, stable forever in wire JSON). | Drives routing; breaking changes require migration. |
| **Payload schema** | Add `spec/<source>-payload.schema.json` (or agreed name under `spec/`). Document in [`spec/README.md`](../spec/README.md). | Single truth for required keys, types, enums. |
| **Golden ingestion fixture** | `examples/ingestion/<name>-sample.json` — valid envelope with `"source": "<id>"` and realistic `payload`. | CI and cross-runtime regression. |
| **Golden canonical fixture** | `examples/canonical/<name>-sample.expected.json` — output of **full** pipeline after normalize (match TS `submit` output). | Assert bit-exact or field-level parity. |

### 2. TypeScript runtime (`runtimes/typescript/`)

| Step | Files / actions |
|------|-----------------|
| **Ajv validator** | [`collectors/validators.ts`](./typescript/collectors/validators.ts): compile schema, export `validate<Source>Payload`, wire `formatAjvErrors`. |
| **`submit()` branch** | [`collectors/pipeline.ts`](./typescript/collectors/pipeline.ts): `if (env.source === "<id>")` → validate payload → `map<Source>PayloadToCanonical` → `finalize`. |
| **Adapter** | New folder [`adapters/<source>/map.ts`](./typescript/adapters/) (+ `README.md`): implement mapper; mirror field semantics from vendor docs. |
| **Tests** | [`collectors/pipeline.test.ts`](./typescript/collectors/pipeline.test.ts): load golden envelope → `submit` → `toEqual` expected canonical. |
| **CLI smoke (optional)** | `pnpm pipeline examples/ingestion/<name>-sample.json` after build. |

### 3. Swift runtime (`runtimes/swift/`)

| Step | Files / actions |
|------|-----------------|
| **Payload validation** | [`OGTEnvelopeAndPayloadValidation.swift`](./swift/Sources/OpenGlucoseTelemetryRuntime/collectors/OGTEnvelopeAndPayloadValidation.swift): allowed keys + required fields (parity with JSON Schema). |
| **`validatePayloadForSource`** | [`OGTCollectorSubmit.swift`](./swift/Sources/OpenGlucoseTelemetryRuntime/collectors/OGTCollectorSubmit.swift): new `case` for `source` id. |
| **Adapter** | New [`adapters/<source>/`](./swift/Sources/OpenGlucoseTelemetryRuntime/adapters/) type conforming to **`OGTSourceAdapter`**: `mapPayload` → `OGTCanonicalGlucoseReadingV01`. |
| **Registry** | [`OGTAdapterRegistry.swift`](./swift/Sources/OpenGlucoseTelemetryRuntime/collectors/OGTAdapterRegistry.swift): `OGTDefaultAdapterRegistry.mapPayload` `switch` arm. |
| **Tests** | Decode golden envelope, `submit`, compare to expected (or key fields); mirror TS. |

### 4. Documentation and parity

| Step | Action |
|------|--------|
| **Adapter README** | Under `adapters/<source>/README.md` (TS and/or Swift): payload fields, mapping notes, upstream reference. |
| **Parity matrix** | Update [`specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md`](../specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md) if behavior intentionally differs. |
| **Consumer docs** | If apps embed subsets (e.g. GlucoseAITracker), note new `source` in their integration docs if relevant. |

### 5. What you do **not** need to duplicate

- **Envelope** wrapper schema is usually unchanged; only `source` and `payload` shape change.
- **Normalize / semantic / OGIS final check** live in **collectors** — reuse; do not reimplement inside the adapter (adapter output is **pre-normalize**).

---

## References

| Runtime | Layout |
|---------|--------|
| TypeScript (Node) | [`typescript/collectors/`](./typescript/collectors/), [`typescript/adapters/`](./typescript/adapters/) |
| Swift (SPM) | [`swift/Sources/OpenGlucoseTelemetryRuntime/collectors/`](./swift/Sources/OpenGlucoseTelemetryRuntime/collectors/), [`swift/.../adapters/`](./swift/Sources/OpenGlucoseTelemetryRuntime/adapters/) |

---

## Adding a new **language** runtime

1. Create `runtimes/<language>/` with that ecosystem’s build system.
2. Add **`collectors/`** and **`adapters/`** implementing the **pipeline layers** above.
3. Wire tests to **`examples/`** and document commands in `runtimes/<language>/README.md`.
4. Register the runtime in [`runtimes/README.md`](./README.md).
