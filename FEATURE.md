# Open Glucose Telemetry — Feature Tracking

Feature backlog for OGT, aligned with [README.md](./README.md). Each row is sized so a **single implementation plan** can cover it without splitting into many sub-tasks.

## Status Legend

- 🔨 **WorkInProgress** — Currently being developed
- 🧪 **Testing** — Feature is complete and being tested
- 🟢 **ReadyToMerge** — PR approved by reviewer, ready to merge
- ✅ **Complete** — Feature is complete and merged
- 📋 **Planned** — Planned but not started
- 🚫 **Blocked** — Blocked by dependencies or issues
- ⏸️ **Paused** — Temporarily paused

## Phase Legend

- **MVP** — Initial vertical slice: mock path, collector, bus, minimal query/stream/export, local dev
- **Next** — Broadens adapters, APIs, and exporters after MVP proves the pipeline
- **Later** — Replay, advanced policy, extra protocols, enterprise posture

## Feature Categories

### 📐 OGIS & canonical model

| Feature ID | Title | Description | Phase | Status | Assignee | Plan Document | Notes |
|------------|-------|-------------|-------|--------|----------|---------------|-------|
| OGIS-001 | Canonical event contract v1 | Define and document the minimum OGIS-aligned event shape (e.g. `glucose.reading`) the runtime accepts, including required timestamps and provenance fields | MVP | 📋 Planned | - | - | Can reference external OGIS specs when published |
| OGIS-002 | Schema validation artifacts | Ship machine-readable validation (e.g. JSON Schema) for the canonical contract and wire errors into the collector | MVP | 📋 Planned | - | - | Enables consistent reject reasons for adapters |

### 🧮 Collector

| Feature ID | Title | Description | Phase | Status | Assignee | Plan Document | Notes |
|------------|-------|-------------|-------|--------|----------|---------------|-------|
| COL-001 | Adapter ingestion boundary | Stable internal API (or gRPC/HTTP) for adapters to submit parsed events to the collector with raw-metadata preservation | MVP | 📋 Planned | - | - | Single responsibility: “events enter here” |
| COL-002 | Validation and semantic gate | Validate incoming events against OGIS-002 schemas and enforce baseline semantic rules before normalization | MVP | 📋 Planned | - | - | Rejects invalid events with structured errors |
| COL-003 | Unit and timestamp normalization | Normalize glucose units and align observed vs received vs processed time fields per OGIS rules | MVP | 📋 Planned | - | - | One plan: converters + clock skew handling policy |
| COL-004 | Deduplication | Idempotent handling of duplicate vendor deliveries using a stable key (subject, device, observed time, source fingerprint) | MVP | 📋 Planned | - | - | Keeps bus and storage clean without adapter cooperation |
| COL-005 | Provenance enrichment | Attach collector metadata (ingest time, adapter id/version, pipeline version) without overwriting source provenance | MVP | 📋 Planned | - | - | Supports traceability in README design principles |
| COL-006 | Subject routing metadata | Tag events for partitioning and downstream fan-out (subject, device, optional tenant id placeholder) | MVP | 📋 Planned | - | - | Feeds bus partitioning; tenant enforcement comes later |
| COL-007 | Policy and tenant controls | Enforce quotas, allow/deny lists, and multi-tenant isolation at ingest | Later | 📋 Planned | - | - | Depends on COL-006 and auth model |

### 📨 Event bus

| Feature ID | Title | Description | Phase | Status | Assignee | Plan Document | Notes |
|------------|-------|-------------|-------|--------|----------|---------------|-------|
| BUS-001 | Durable event log | Append-only store for normalized events with configurable retention | MVP | 📋 Planned | - | - | Backend-agnostic interface (e.g. pluggable impl for dev vs prod) |
| BUS-002 | Publish and fan-out | Dispatch committed events to query projection updates, realtime gateways, and exporter workers | MVP | 📋 Planned | - | - | One dispatcher; subscribers register by concern |
| BUS-003 | Partitioning by subject/device | Keys and ordering guarantees sufficient for per-subject replay and concurrent consumers | Next | 📋 Planned | - | - | MVP can be single-partition dev mode first |

### 🔌 Adapters

| Feature ID | Title | Description | Phase | Status | Assignee | Plan Document | Notes |
|------------|-------|-------------|-------|--------|----------|---------------|-------|
| ADP-001 | Mock adapter and sample stream | Generate realistic canonical or near-canonical events for local demos and tests | MVP | 📋 Planned | - | - | Matches README “sample event stream” |
| ADP-002 | File / CSV import adapter | Batch ingestion from files with column mapping into canonical events | Next | 📋 Planned | - | - | Good second adapter; no live credentials |
| ADP-003 | Webhook ingestion adapter | HTTP endpoint that accepts vendor-specific JSON and maps to canonical events via configurable transforms | Next | 📋 Planned | - | - | Pairs with EXP-001 patterns (signatures, retries) |
| ADP-004 | First cloud vendor adapter | One real vendor API integration using shared auth + polling/receive patterns | Next | 📋 Planned | - | - | Vendor choice tracked separately; keep adapter thin |
| ADP-005 | BLE adapter skeleton | Discover/connect lifecycle and binary payload handoff to mapping layer (no full device matrix) | Later | 📋 Planned | - | - | Platform-specific; scope per OS |

### 🔎 Query APIs

| Feature ID | Title | Description | Phase | Status | Assignee | Plan Document | Notes |
|------------|-------|-------------|-------|--------|----------|---------------|-------|
| QRY-001 | REST query foundation | Versioned HTTP API (`/v1/...`), error model, optional API key or dev auth | MVP | 📋 Planned | - | - | OpenAPI recommended |
| QRY-002 | Glucose readings and latest | `GET .../glucose/readings` and `.../glucose/latest` backed by bus projections | MVP | 📋 Planned | - | - | Matches README examples |
| QRY-003 | Alerts endpoint | `GET .../alerts` for normalized alert events | Next | 📋 Planned | - | - | Requires alert event type in canonical model |

### ⚡ Realtime streaming

| Feature ID | Title | Description | Phase | Status | Assignee | Plan Document | Notes |
|------------|-------|-------------|-------|--------|----------|---------------|-------|
| RT-001 | WebSocket live stream | Subscribe by subject (and optionally device); push normalized events as they commit | MVP | 📋 Planned | - | - | README “Getting Started” WebSocket example |
| RT-002 | Additional stream transports | MQTT broker bridge and/or gRPC server streaming mirroring the same event stream | Later | 📋 Planned | - | - | Same semantics as RT-001 |

### 📤 Exporters

| Feature ID | Title | Description | Phase | Status | Assignee | Plan Document | Notes |
|------------|-------|-------------|-------|--------|----------|---------------|-------|
| EXP-001 | Webhook exporter | Configurable HTTPS delivery with retries, signing, and dead-letter visibility | MVP | 📋 Planned | - | - | First downstream integration path |
| EXP-002 | FHIR exporter | Map canonical glucose readings to FHIR Observation (or Bundle) for clinical consumers | Next | 📋 Planned | - | - | Start with minimal must-have fields |
| EXP-003 | Warehouse / analytics sink | Batch or streaming export to columnar/object storage for pipelines | Later | 📋 Planned | - | - | Schema contract with data teams |

### 🛠️ SDKs & developer experience

| Feature ID | Title | Description | Phase | Status | Assignee | Plan Document | Notes |
|------------|-------|-------------|-------|--------|----------|---------------|-------|
| SDK-001 | TypeScript adapter SDK | Types for canonical events, validation helpers, and client for COL-001 ingestion | MVP | 📋 Planned | - | - | README roadmap: adapter SDK (TypeScript) first |
| SDK-002 | Additional language SDKs | Python, Swift, or Kotlin clients matching SDK-001 surface | Next | 📋 Planned | - | - | One plan per language is fine |
| DEV-001 | Local dev environment | One-command bootstrap (e.g. compose) for collector, bus, mock adapter, and sample queries | MVP | 📋 Planned | - | - | README “local collector runtime” |
| DEV-002 | End-to-end examples | Documented walkthrough: mock → collector → bus → query + WebSocket | MVP | 📋 Planned | - | - | Lives under `/examples` when code exists |

### ⏪ Replay & advanced delivery

| Feature ID | Title | Description | Phase | Status | Assignee | Plan Document | Notes |
|------------|-------|-------------|-------|--------|----------|---------------|-------|
| RPL-001 | Event replay API | Replay historical events for a subject or device into a stream for catch-up consumers | Later | 📋 Planned | - | - | README future: replay service |
| RPL-002 | Consumer offset registry | Track per-subscriber position for at-least-once replay without duplicates downstream | Later | 📋 Planned | - | - | Complements RPL-001 |

### 🏗️ Platform, ops & observability

| Feature ID | Title | Description | Phase | Status | Assignee | Plan Document | Notes |
|------------|-------|-------------|-------|--------|----------|---------------|-------|
| PLAT-001 | Health and readiness | `/health` and `/ready` for orchestration | MVP | 📋 Planned | - | - | Minimal ops surface |
| PLAT-002 | Observability baseline | Structured logs with correlation id from adapter through exporter; basic RED metrics | MVP | 📋 Planned | - | - | README: observable pipeline |
| PLAT-003 | Multi-tenant deployment profile | Configuration presets for isolated namespaces and limits | Later | 📋 Planned | - | - | Aligns with README future capabilities |

### 🧪 Quality & testing

| Feature ID | Title | Description | Phase | Status | Assignee | Plan Document | Notes |
|------------|-------|-------------|-------|--------|----------|---------------|-------|
| QA-001 | Collector golden tests | Fixture-based tests for validation, normalization, dedup, and provenance | MVP | 📋 Planned | - | - | Locks behavior described in README |
| QA-002 | Pipeline integration test | Mock adapter → collector → bus → query (and optionally WebSocket) in CI | MVP | 📋 Planned | - | - | Guards the happy path |

---

## How to Use This File

### Adding a New Feature

1. Add a row in the appropriate category table.
2. Assign a unique Feature ID (e.g. `COL-008`).
3. Fill Title, Description, Phase, Status, Assignee, and Notes.
4. Set status to `📋 Planned` initially.
5. Link a plan document when design is drafted.

### Updating Feature Status

1. Find the feature in the table.
2. Update the Status column.
3. Update Assignee if ownership changes.
4. Add notes about progress or blockers.

**Note:** The `🟢 ReadyToMerge` status should be assigned by the reviewer after PR approval.

### Example Workflow

```text
1. Feature starts: Status = 📋 Planned, Assignee = -
2. Developer picks it up: Status = 🔨 WorkInProgress, Assignee = @username
3. Code complete: Status = 🧪 Testing, Assignee = @username
4. Reviewer approves PR: Status = 🟢 ReadyToMerge, Assignee = @username
5. Merged: Status = ✅ Complete, Assignee = @username
```

**Last Updated:** 2026-03-28
