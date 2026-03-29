# OGT MVP — Telemetry / Pipeline Plan (GlucoseAITracker integration)

**Audience:** OGT contributors and GlucoseAITracker (GLUCOSE-009) implementers  
**Scope:** Phase 1 MVP — ingestion, validation, normalization, first real source path (HealthKit-shaped data), OGIS mapping, fixtures, dev harness  
**Non-goals for MVP:** Durable event bus, REST/WebSocket APIs, multi-tenant policy, Dexcom cloud adapter, FHIR export

---

## Goal

Deliver a **vendor-neutral ingestion and normalization pipeline** that:

1. Accepts **adapter submissions** in a stable **ingestion envelope** (raw payload + metadata).
2. **Validates** payloads against structural and semantic rules.
3. **Normalizes** timestamps and units.
4. Maps to **OGIS canonical** `glucose.reading` events (v0.1) defined in the OGIS repository.
5. Ships **test fixtures** and a **minimal dev harness** so behavior is reproducible without an iPhone.

**OGT = ingestion / motion layer. OGIS = schema / meaning layer.** OGT depends on OGIS artifacts (JSON Schema + RFCs) as the source of truth for canonical output shape.

---

## Relationship to OpenGlucoseInteroperabilityStandard (OGIS)

| Concern | Owner |
|--------|--------|
| Canonical `glucose.reading` fields, enums, time/unit/provenance semantics | OGIS repo (`/spec`, `/schemas/jsonschema`, `/rfcs`) |
| Ingestion envelope, adapter contracts, validation orchestration, normalization code | OGT repo (`/collectors`, `/adapters`, `/dev`) |

OGT **does not** redefine canonical semantics; it **implements** validators and mappers that conform to OGIS v0.1.

**Field-name alignment:** The root `README.md` example uses names such as `timestamp_observed` and a nested `glucose` object. GLUCOSE-009 and OGIS MVP v0.1 target a **single flat canonical shape** (e.g. `observed_at`, top-level `value` / `unit`) until RFC-0001 and `glucose.reading` JSON Schema are merged. This plan assumes **OGIS schema v0.1 is authoritative**; OGT mappers emit exactly that shape.

---

## Phase 1 — MVP Pipeline

### 1. Repository structure

Target layout for the MVP slice (logical; language/runtime choice is implementation detail, e.g. TypeScript for portable CI + Swift in app):

```text
OpenGlucoseTelemetry/
├── collectors/           # validation, normalization, dedupe hooks (MVP: in-process pipeline)
├── adapters/             # source-specific: healthkit, mock, …
├── spec/                 # OGT-local contracts only (ingestion envelope JSON Schema); NOT a copy of full OGIS
├── examples/             # sample envelopes + canonical outputs (may symlink or reference OGIS /examples)
├── dev/                  # harness scripts, docker-compose (optional), fixture runners
├── specifications/
│   ├── plans/
│   └── tasks/
└── README.md             # updated “Core README” section for MVP (see §2)
```

**Deliverable:** Directories exist, CI runs tests from `dev/` or package test script, README points to OGIS for canonical schemas.

---

### 2. Core README (MVP section)

Extend or refactor the main `README.md` with a concise subsection:

- **OGT** = ingestion layer: adapters → collector (validate, normalize, dedupe) → **canonical OGIS events** out.
- **OGIS** = schema layer: event types, semantics, JSON Schema.
- **How they connect:** Adapters produce ingestion envelopes; collector validates **envelope + mapped canonical event** against OGIS; only OGIS-compliant events are considered pipeline output.

**Deliverable:** Merged README section; link to OGIS repo and to `spec/ingestion-envelope.schema.json` (or equivalent).

---

### 3. Ingestion contract (envelope)

Adapters submit a **wrapper** around vendor-specific data so the collector has uniform metadata for tracing and provenance.

**Normative example (v0.1 draft):**

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

| Field | Purpose |
|-------|--------|
| `source` | Stable adapter channel id (`healthkit`, `mock`, …). |
| `payload` | Opaque-to-collector JSON per adapter; HealthKit adapter uses a defined serializable shape (see §6). |
| `received_at` | When OGT received the submission (RFC 3339). |
| `trace_id` | Correlation for logs and tests. |
| `adapter` | `id` + semver `version` for provenance. |

**Deliverable:** JSON Schema under `spec/` + short markdown in `spec/README.md`.

---

### 4. Validation layer

**Stages:**

1. **Envelope validation** — required top-level fields; `received_at` parseable; `trace_id` non-empty; `adapter.id` / `adapter.version` present.
2. **Adapter-specific structural validation** — optional JSON Schema per `source` (e.g. `payload` shape for `healthkit`).
3. **Canonical validation** — after mapping, validate **OGIS** `glucose.reading` v0.1 via JSON Schema from OGIS repo (git submodule, package dependency, or copied pinned version with checksum in OGT).

**Semantic rules (MVP minimum):**

| Rule | Description |
|------|-------------|
| Required fields | As per OGIS `glucose.reading` required set. |
| Value range | Glucose value within OGIS-defined bounds for `mg/dL` / `mmol/L` (align with OGIS semantic doc). |
| Timestamps | `observed_at` (and optional `source_recorded_at`) parseable, not unreasonably in the future; ordering policy documented. |
| Unit validity | Only allowed unit strings per OGIS; value consistent with unit. |

**Deliverable:** Validator module + structured errors `{ code, message, field?, trace_id }`.

---

### 5. Normalization layer

Applied **after** initial mapping into canonical fields, **before** final schema validation if order simplifies implementation:

| Step | Description |
|------|-------------|
| Timestamp normalization | UTC; trim sub-ms if needed; optional clock-skew clamp (policy in OGIS time semantics). |
| Unit normalization | Either store canonical unit per OGIS policy **or** dual fields (`value_reported`, `unit_reported`, `value_normalized`, `unit_normalized`) — **decide in OGIS v0.1**; OGT implements chosen policy. |
| Light cleanup | Strip nulls, coerce number types, bounded string lengths for device/provenance fields. |

**Deliverable:** Pure functions / module with unit tests; no I/O.

---

### 6. HealthKit adapter (first real implementation)

**Constraint:** Apple HealthKit APIs are **iOS-only**. For the OGT repository to remain testable on Linux CI:

- **Reference path A (recommended for OGT repo):** Implement `adapters/healthkit` as a **mapper from a serializable HealthKit sample JSON** (fixture) → intermediate → OGIS. Same code paths used by GlucoseAITracker when it builds the payload from `HKQuantitySample`.
- **Reference path B:** Swift package `adapters/apple-healthkit` in OGT monorepo, executed on macOS CI only.

**Responsibilities:**

1. Define **HealthKit payload JSON** schema (uuid, value, unit string, startDate, endDate, source name/bundle id, metadata map).
2. Map to OGT internal “pre-canonical” struct (optional) or directly to OGIS fields.
3. Populate **provenance** (`source_system`, `raw_event_id`, `adapter_version`, `ingested_at`).
4. Set `measurement_source` per OGIS enum (e.g. cgm vs bgm heuristics from HK source revision / metadata when possible).

**Deliverable:** Adapter module + fixtures (§8); documentation for GlucoseAITracker to construct the same `payload` from live samples.

---

### 7. OGIS mapping step

Explicit pipeline stage:

```text
IngestionEnvelope → [Adapter: source → intermediate] → [Mapper: → glucose.reading v0.1] → Normalize → Validate (OGIS JSON Schema) → Output
```

**Deliverable:** Single public function or CLI entry point: `runPipeline(envelope) -> Result<CanonicalEvent, PipelineError>`.

---

### 8. Test fixtures

| Fixture | Purpose |
|---------|--------|
| `examples/ingestion/healthkit-sample.json` | Valid envelope + realistic `payload`. |
| `examples/canonical/healthkit-sample.expected.json` | Expected `glucose.reading` after pipeline. |
| Negative cases | Missing field, bad unit, future timestamp, out-of-range value. |

**Deliverable:** Golden tests in CI asserting fixture → expected canonical JSON (stable stringify order or semantic JSON compare).

---

### 9. Minimal dev harness

**Options (pick one for MVP):**

- **Node/TS:** `pnpm tsx dev/run-pipeline.ts examples/ingestion/healthkit-sample.json`
- **Python:** `python dev/run_pipeline.py examples/ingestion/healthkit-sample.json`
- **Shell + `jq`:** only if validation runs in a small compiled helper — less ideal.

**Behavior:** Load sample path from argv, run adapter + mapper + validation, print canonical JSON to stdout, exit non-zero on error with stderr details.

**Deliverable:** Documented in `dev/README.md`; one command in root README under “Getting Started (MVP)”.

---

## GlucoseAITracker (GLUCOSE-009) — feature flag and insights

The app integrates OGT without a big-bang cutover:

- **Feature flag** (`UserDefaults`, default off): selects **legacy ingestion** vs **OGT pipeline** for writes/sync.
- **Single insights engine:** all insight and meal–glucose analysis code consumes **OGIS-aligned canonical readings** only. When the flag is off, a **legacy bridge** maps existing `Glucose` / Core Data rows into the same canonical shape so insight logic is not duplicated.
- **OGT handoff:** GlucoseAITracker either embeds Swift pipeline logic aligned with this repo’s golden fixtures or calls a shared module; behavioral parity is validated by comparing fixture outputs with in-app runs.

**Authoritative app plan:** `GlucoseAITracker/specifications/plans/GLUCOSE-009-OGT-OGIS-INTEGRATION-PLAN.md`.

---

## Milestones

1. **M1:** Envelope schema + HealthKit payload schema + mock adapter (no HK).
2. **M2:** HealthKit fixture adapter + OGIS mapping + normalization + OGIS validation wired.
3. **M3:** Golden tests + dev harness + README updates.
4. **M4:** Handoff doc for GlucoseAITracker: how to build envelopes from `HKQuantitySample` and call the same pipeline (in-process Swift port or shared JSON round-trip).
5. **M5:** Document feature-flag expectations and fixture parity checks for GlucoseAITracker QA (reference GLUCOSE-009 tasks).

---

## Traceability to FEATURES.md

`FEATURES.md` (and redirect stub `FEATURE.md`) uses phase **MVP (GAT)** for this plan. In-scope feature IDs include:

- **OGIS-001, OGIS-002** — canonical contract consumption and validation wiring  
- **COL-001–COL-005** — ingestion envelope through provenance (in-process)  
- **ADP-001, ADP-006** — mock adapter + HealthKit **fixture** adapter  
- **DEV-003** — minimal CLI/script harness (§9)  
- **QA-001** — golden tests / fixtures  

**Next** (not GAT MVP): COL-006 (full routing), BUS-*, QRY-*, RT-001, EXP-001, SDK-001, DEV-001/002, PLAT-*, QA-002 (bus → query path).

---

## Document history

| Date | Change |
|------|--------|
| 2026-03-29 | Initial MVP pipeline plan for GlucoseAITracker integration |
| 2026-03-29 | GlucoseAITracker: feature flag + unified insights engine (see GLUCOSE-009 app plan) |
| 2026-03-29 | `FEATURE.md`: phase **MVP (GAT)** aligned; Traceability lists feature IDs |
| 2026-03-29 | `FEATURES.md` + completion summary in `specifications/summary/`; GAT rows marked complete |
