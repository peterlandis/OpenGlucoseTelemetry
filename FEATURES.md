# Open Glucose Telemetry — Feature tracking

Feature backlog for OGT, aligned with [README.md](./README.md). Each row is sized so a **single implementation plan** can cover it without splitting into many sub-tasks.

> **Naming:** This file is **`FEATURES.md`**. [FEATURE.md](./FEATURE.md) redirects here for older links.

## Status legend

- 🔨 **WorkInProgress** — Currently being developed
- 🧪 **Testing** — Feature is complete and being tested
- 🟢 **ReadyToMerge** — PR approved by reviewer, ready to merge
- ✅ **Complete** — Feature is complete and merged (or delivered on an integration branch pending merge to default)
- 📋 **Planned** — Planned but not started
- 🚫 **Blocked** — Blocked by dependencies or issues
- ⏸️ **Paused** — Temporarily paused

## Phase legend

- **MVP (GAT)** — In scope for the **GlucoseAITracker integration** vertical slice: in-process collector, envelope + validation + normalization + OGIS mapping, mock + HealthKit **fixture** adapter, golden tests, minimal `runtimes/typescript/dev/` CLI. See [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md). *Explicitly out of this slice:* durable bus, REST/WebSocket query APIs, webhook exporter, full local compose.
- **MVP** — Broader OGT product MVP (full README vision: bus, query, stream, exporter, etc.) when tracked separately from the GAT slice
- **Next** — After the GAT pipeline MVP or after broader MVP
- **Later** — Replay, advanced policy, extra protocols, enterprise posture

## Feature categories

### 📐 OGIS & canonical model

| Feature ID | Title | Description | Phase | Status | Assignee | Plan document | Notes |
|------------|-------|-------------|-------|--------|----------|---------------|-------|
| OGIS-001 | Canonical event contract v1 | Define and document the minimum OGIS-aligned event shape (e.g. `glucose.reading`) the runtime accepts, including required timestamps and provenance fields | MVP (GAT) | ✅ Complete | - | [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md) | **OGT:** consumes authoritative OGIS v0.1; pinned copy under `spec/pinned/` |
| OGIS-002 | Schema validation artifacts | Ship machine-readable validation (e.g. JSON Schema) for the canonical contract and wire errors into the collector | MVP (GAT) | ✅ Complete | - | [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md) | **OGT:** Ajv validates mapped output against pinned `glucose.reading` v0.1 |

### 🧮 Collector

| Feature ID | Title | Description | Phase | Status | Assignee | Plan document | Notes |
|------------|-------|-------------|-------|--------|----------|---------------|-------|
| COL-001 | Adapter ingestion boundary | Stable internal API (or gRPC/HTTP) for adapters to submit parsed events to the collector with raw-metadata preservation | MVP (GAT) | ✅ Complete | - | [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md) | **GAT:** ingestion **envelope** + in-process `submit()` (`runtimes/typescript/collectors/core/collector-engine.ts`, barrel `collectors/pipeline.ts`) |
| COL-002 | Validation and semantic gate | Validate incoming events against OGIS-002 schemas and enforce baseline semantic rules before normalization | MVP (GAT) | ✅ Complete | - | [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md) | Envelope + per-source payload + semantic rules + canonical schema |
| COL-003 | Unit and timestamp normalization | Normalize glucose units and align observed vs received vs processed time fields per OGIS rules | MVP (GAT) | ✅ Complete | - | [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md) | `runtimes/typescript/collectors/normalization/normalize.ts` — UTC ms, **mg/dL** normalization per GAT policy |
| COL-004 | Deduplication | Idempotent handling of duplicate vendor deliveries using a stable key (subject, device, observed time, source fingerprint) | MVP (GAT) | ✅ Complete | - | [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md) | Optional `DedupeTracker` on `submit()`; key `(subject_id, observed_at, raw_event_id)` |
| COL-005 | Provenance enrichment | Attach collector metadata (ingest time, adapter id/version, pipeline version) without overwriting source provenance | MVP (GAT) | ✅ Complete | - | [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md) | Envelope `trace_id`, `adapter`, `received_at`; canonical `provenance` + optional `received_at` |
| COL-006 | Subject routing metadata | Tag events for partitioning and downstream fan-out (subject, device, optional tenant id placeholder) | Next | 📋 Planned | - | - | GAT MVP: optional minimal tags only; full routing with bus is Next |
| COL-007 | Policy and tenant controls | Enforce quotas, allow/deny lists, and multi-tenant isolation at ingest | Later | 📋 Planned | - | - | Depends on COL-006 and auth model |

### 📨 Event bus

| Feature ID | Title | Description | Phase | Status | Assignee | Plan document | Notes |
|------------|-------|-------------|-------|--------|----------|---------------|-------|
| BUS-001 | Durable event log | Append-only store for normalized events with configurable retention | Next | 📋 Planned | - | [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md) | Out of GAT MVP (non-goal: durable bus) |
| BUS-002 | Publish and fan-out | Dispatch committed events to query projection updates, realtime gateways, and exporter workers | Next | 📋 Planned | - | [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md) | Out of GAT MVP |
| BUS-003 | Partitioning by subject/device | Keys and ordering guarantees sufficient for per-subject replay and concurrent consumers | Next | 📋 Planned | - | - | MVP can be single-partition dev mode first |

### 🔌 Adapters

| Feature ID | Title | Description | Phase | Status | Assignee | Plan document | Notes |
|------------|-------|-------------|-------|--------|----------|---------------|-------|
| ADP-001 | Mock adapter and sample stream | Generate realistic canonical or near-canonical events for local demos and tests | MVP (GAT) | ✅ Complete | - | [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md) | `source: mock`, `runtimes/typescript/adapters/mock/map.ts`, integration tests |
| ADP-006 | HealthKit fixture adapter | Map serializable HealthKit sample JSON (envelope `source: healthkit`) to OGIS `glucose.reading` via collector | MVP (GAT) | ✅ Complete | - | [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md) | `runtimes/typescript/adapters/healthkit/map.ts` + `spec/healthkit-payload.schema.json` |
| ADP-007 | Dexcom fixture adapter | Map serializable Dexcom EGV-style JSON (`source: dexcom`) to OGIS `glucose.reading` (trend/quality best-effort); no live cloud client | MVP (GAT) | ✅ Complete | - | [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md) | `runtimes/typescript/adapters/dexcom/map.ts` + `spec/dexcom-payload.schema.json`; **ADP-004** remains live cloud API |
| ADP-002 | File / CSV import adapter | Batch ingestion from files with column mapping into canonical events | Next | 📋 Planned | - | - | Good second adapter; no live credentials |
| ADP-003 | Webhook ingestion adapter | HTTP endpoint that accepts vendor-specific JSON and maps to canonical events via configurable transforms | Next | 📋 Planned | - | - | Pairs with EXP-001 patterns (signatures, retries) |
| ADP-004 | First cloud vendor adapter | One real vendor API integration using shared auth + polling/receive patterns | Next | 📋 Planned | - | - | Vendor choice tracked separately; keep adapter thin |
| ADP-005 | BLE adapter skeleton | Discover/connect lifecycle and binary payload handoff to mapping layer (no full device matrix) | Later | 📋 Planned | - | - | Platform-specific; scope per OS |

### 🔎 Query APIs

| Feature ID | Title | Description | Phase | Status | Assignee | Plan document | Notes |
|------------|-------|-------------|-------|--------|----------|---------------|-------|
| QRY-001 | REST query foundation | Versioned HTTP API (`/v1/...`), error model, optional API key or dev auth | Next | 📋 Planned | - | [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md) | Out of GAT MVP |
| QRY-002 | Glucose readings and latest | `GET .../glucose/readings` and `.../glucose/latest` backed by bus projections | Next | 📋 Planned | - | [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md) | Out of GAT MVP |
| QRY-003 | Alerts endpoint | `GET .../alerts` for normalized alert events | Next | 📋 Planned | - | - | Requires alert event type in canonical model |

### ⚡ Realtime streaming

| Feature ID | Title | Description | Phase | Status | Assignee | Plan document | Notes |
|------------|-------|-------------|-------|--------|----------|---------------|-------|
| RT-001 | WebSocket live stream | Subscribe by subject (and optionally device); push normalized events as they commit | Next | 📋 Planned | - | [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md) | Out of GAT MVP |
| RT-002 | Additional stream transports | MQTT broker bridge and/or gRPC server streaming mirroring the same event stream | Later | 📋 Planned | - | - | Same semantics as RT-001 |

### 📤 Exporters

| Feature ID | Title | Description | Phase | Status | Assignee | Plan document | Notes |
|------------|-------|-------------|-------|--------|----------|---------------|-------|
| EXP-001 | Webhook exporter | Configurable HTTPS delivery with retries, signing, and dead-letter visibility | Next | 📋 Planned | - | [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md) | Out of GAT MVP |
| EXP-002 | FHIR exporter | Map canonical glucose readings to FHIR Observation (or Bundle) for clinical consumers | Next | 📋 Planned | - | - | Start with minimal must-have fields |
| EXP-003 | Warehouse / analytics sink | Batch or streaming export to columnar/object storage for pipelines | Later | 📋 Planned | - | - | Schema contract with data teams |

### 🛠️ SDKs & developer experience

| Feature ID | Title | Description | Phase | Status | Assignee | Plan document | Notes |
|------------|-------|-------------|-------|--------|----------|---------------|-------|
| SDK-001 | TypeScript adapter SDK | Types for canonical events, validation helpers, and client for COL-001 ingestion | Next | 📋 Planned | - | [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md) | GAT MVP: in-repo TS modules; **published** SDK deferred |
| SDK-002 | Additional language SDKs | Python, Swift, or Kotlin clients matching SDK-001 surface | Next | 📋 Planned | - | - | One plan per language is fine |
| DEV-001 | Local dev environment | One-command bootstrap (e.g. compose) for collector, bus, mock adapter, and sample queries | Next | 📋 Planned | - | [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md) | GAT MVP: `pnpm verify` only; full compose deferred |
| DEV-003 | GlucoseAITracker MVP dev harness | CLI or script: load fixture → run pipeline → print canonical JSON (stdout) | MVP (GAT) | ✅ Complete | - | [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md) | `runtimes/typescript/dev/run-pipeline.ts`, `pnpm pipeline` from repo root (requires `pnpm build`) |
| DEV-002 | End-to-end examples | Documented walkthrough: mock → collector → bus → query + WebSocket | Next | 📋 Planned | - | [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md) | Out of GAT MVP until bus/query exist |

### ⏪ Replay & advanced delivery

| Feature ID | Title | Description | Phase | Status | Assignee | Plan document | Notes |
|------------|-------|-------------|-------|--------|----------|---------------|-------|
| RPL-001 | Event replay API | Replay historical events for a subject or device into a stream for catch-up consumers | Later | 📋 Planned | - | - | README future: replay service |
| RPL-002 | Consumer offset registry | Track per-subscriber position for at-least-once replay without duplicates downstream | Later | 📋 Planned | - | - | Complements RPL-001 |

### 🏗️ Platform, ops & observability

| Feature ID | Title | Description | Phase | Status | Assignee | Plan document | Notes |
|------------|-------|-------------|-------|--------|----------|---------------|-------|
| PLAT-001 | Health and readiness | `/health` and `/ready` for orchestration | Next | 📋 Planned | - | [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md) | Out of GAT MVP (no standalone service) |
| PLAT-002 | Observability baseline | Structured logs with correlation id from adapter through exporter; basic RED metrics | Next | 📋 Planned | - | [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md) | **GAT slice done:** `trace_id` + stable pipeline error `code`s; full RED metrics **Next** |
| PLAT-003 | Multi-tenant deployment profile | Configuration presets for isolated namespaces and limits | Later | 📋 Planned | - | - | Aligns with README future capabilities |

### 🧪 Quality & testing

| Feature ID | Title | Description | Phase | Status | Assignee | Plan document | Notes |
|------------|-------|-------------|-------|--------|----------|---------------|-------|
| QA-001 | Collector golden tests | Fixture-based tests for validation, normalization, dedup, and provenance | MVP (GAT) | ✅ Complete | - | [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md) | Vitest golden + negative fixtures; `pnpm verify` smoke |
| QA-002 | Pipeline integration test | Mock adapter → collector → bus → query (and optionally WebSocket) in CI | Next | 📋 Planned | - | [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md) | GAT MVP: mock/HealthKit → collector → result; bus/query path is Next |

### 🔗 GlucoseAITracker cross-runtime parity & consumer docs (wave 2)

| Feature ID | Title | Description | Phase | Status | Assignee | Plan document | Notes |
|------------|-------|-------------|-------|--------|----------|---------------|-------|
| PAR-001 | TS ↔ Swift parity matrix | Document rule-by-rule alignment between `runtimes/typescript/collectors/validation/semantic.ts` / `normalization/normalize.ts` and GlucoseAITracker `OGTGlucoseIngestPipeline` + mapper; call out intentional drift | Next | ✅ Complete | - | [OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-PLAN.md](specifications/plans/OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-PLAN.md) | Delivered: `specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md` |
| PAR-002 | Shared golden canonical fixtures | Process (and optional artifacts) so `glucose.reading` JSON from TS `pnpm pipeline` can be compared to Swift-exported or hand-synced JSON | Next | ✅ Complete | - | [OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-PLAN.md](specifications/plans/OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-PLAN.md) | `examples/canonical/README.md`, `manual-sample.swift-export.json`, `pnpm parity:check` |
| DOC-005 | Consumer pattern documentation | Extend handoff/README: persist native row → derive OGIS → semantic gate; link GlucoseAITracker `OGT-OGIS-INTEGRATION.md` | Next | ✅ Complete | - | [OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-PLAN.md](specifications/plans/OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-PLAN.md) | `OGT-GLUCOSE-009-CONSUMPTION.md`, root `README.md`, `runtimes/typescript/collectors/README.md` |

---

## GlucoseAITracker integration (MVP)

End-to-end MVP for **GLUCOSE-009**: ingestion envelope, validation, normalization, HealthKit-shaped adapter + fixtures, dev harness. Does not require the full event bus or query APIs. GlucoseAITracker uses a **feature flag** for legacy vs OGT ingestion and a **unified insights engine** on canonical readings; see its GLUCOSE-009 plan.

Rows marked **MVP (GAT)** above match this slice; other phases remain **Next**/**Later** until the broader OGT roadmap is executed.

| Document | Purpose |
|----------|---------|
| [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](specifications/plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md) | Detailed pipeline plan (repo layout, contract, layers, HealthKit, harness) |
| [OGT-MVP-IMPLEMENTATION-TASKS.md](specifications/tasks/OGT-MVP-IMPLEMENTATION-TASKS.md) | Checkbox implementation tasks (all complete for GAT scope) |
| [OGT-MVP-GAT-COMPLETION-SUMMARY.md](specifications/summary/OGT-MVP-GAT-COMPLETION-SUMMARY.md) | What shipped for this slice and where it lives in the repo |
| [OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-PLAN.md](specifications/plans/OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-PLAN.md) | Wave 2: TS ↔ Swift parity matrix, golden fixture process, consumer docs |
| [OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-TASKS.md](specifications/tasks/OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-TASKS.md) | Checkbox tasks for wave 2 |

**Upstream dependency:** OGIS `glucose.reading` v0.1 JSON Schema and time/unit/provenance docs — see OpenGlucoseInteroperabilityStandard MVP plan. **Wave 2 alignment:** [OGIS-IMPLEMENTER-INTEROP-GUIDANCE-PLAN.md](../OpenGlucoseInteroperabilityStandard/specifications/plans/OGIS-IMPLEMENTER-INTEROP-GUIDANCE-PLAN.md) when repos are siblings (same parent folder).

---

## How to use this file

### Adding a new feature

1. Add a row in the appropriate category table.
2. Assign a unique Feature ID (e.g. `COL-008`).
3. Fill Title, Description, Phase, Status, Assignee, and Notes.
4. Set status to `📋 Planned` initially.
5. Link a plan document when design is drafted.

### Updating feature status

1. Find the feature in the table.
2. Update the Status column.
3. Update Assignee if ownership changes.
4. Add notes about progress or blockers.

**Note:** The `🟢 ReadyToMerge` status should be assigned by the reviewer after PR approval.

### Example workflow

```text
1. Feature starts: Status = 📋 Planned, Assignee = -
2. Developer picks it up: Status = 🔨 WorkInProgress, Assignee = @username
3. Code complete: Status = 🧪 Testing, Assignee = @username
4. Reviewer approves PR: Status = 🟢 ReadyToMerge, Assignee = @username
5. Merged: Status = ✅ Complete, Assignee = @username
```

**Last updated:** 2026-03-30 (PAR-001/002, DOC-005 — cross-runtime parity & consumer docs wave 2)
