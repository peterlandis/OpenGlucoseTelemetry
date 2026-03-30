# Open Glucose Telemetry (OGT)

OGT is an open, vendor-neutral telemetry and collection framework for ingesting, validating, normalizing, and streaming glucose-related data across devices, applications, and clinical systems.

## Mission

Glucose data today is fragmented across proprietary vendor APIs, inconsistent schemas, and siloed applications. Every new product must rebuild integrations from scratch.

OGT solves this by providing a unified telemetry layer that enables:

- standardized ingestion of glucose data
- real-time and historical data streaming
- consistent data pipelines across vendors
- seamless integration for apps, AI, and clinical systems

> Integrate once. Stream everywhere.

---

## Short version

OGT sits between source systems and downstream consumers as the runtime framework that ingests raw glucose data, transforms it into OGIS-compliant events, and delivers it through shared query, streaming, and export paths.

---

## For implementers

Use these docs when **implementing a runtime**, **adding a new provider (`source`)**, or **matching golden fixtures** (avoid duplicating long checklists in this file — they live in **`runtimes/RUNTIME-TEMPLATE.md`**).

| Doc | What it covers |
|-----|----------------|
| **[`runtimes/RUNTIME-TEMPLATE.md`](./runtimes/RUNTIME-TEMPLATE.md)** | **Pipeline layers** (numbered table), data flow, **adding a new provider** (spec → examples → TS + Swift files), **adding a new language runtime** |
| **[`runtimes/README.md`](./runtimes/README.md)** | Runtimes index, short layer list, links to TS / Swift READMEs and architectures |
| **[`runtimes/typescript/ARCHITECTURE.md`](./runtimes/typescript/ARCHITECTURE.md)** | TypeScript `submit()` flow (diagrams) |
| **[`runtimes/swift/ARCHITECTURE.md`](./runtimes/swift/ARCHITECTURE.md)** | Swift collector flow (diagrams) |

The **Repository layout** section below repeats a **one-paragraph** summary of MVP stages and points to the same template for the full checklist.

---

## Repository layout

This repository is organized as **shared contracts** plus **per-runtime implementations**:

| Area | Purpose |
|------|---------|
| [`spec/`](./spec/) | JSON Schemas, pinned OGIS, schema READMEs (language-agnostic contract) |
| [`examples/`](./examples/) | Golden ingestion and canonical JSON fixtures |
| [`specifications/`](./specifications/) | Plans, handoff, parity matrices |
| [`runtimes/`](./runtimes/) | Implementations — see [`runtimes/README.md`](./runtimes/README.md); every runtime follows [`runtimes/RUNTIME-TEMPLATE.md`](./runtimes/RUNTIME-TEMPLATE.md) (`collectors/` + `adapters/`) |

### Runtime pipeline layers (MVP)

Each language runtime under [`runtimes/`](./runtimes/) implements the same **ordered stages**: **ingress** (envelope) → **envelope validation** → **per-source payload validation** → **adapter map** (`adapters/<source>/`) → **normalize** → **semantic rules** → **optional dedupe** → **OGIS `glucose.reading` v0.1 validation** → **success or structured error**. **`collectors/`** own orchestration; **`adapters/`** own vendor JSON → pre-normalize canonical fields.

**Numbered layer table, per-runtime file paths, and step-by-step “new provider” work:** **[`runtimes/RUNTIME-TEMPLATE.md`](./runtimes/RUNTIME-TEMPLATE.md)** (see also **[For implementers](#for-implementers)** above).

**Adding a new provider (`source`):** add payload schema under [`spec/`](./spec/), golden JSON under [`examples/`](./examples/), then implement routing + adapter in **each** runtime (TypeScript + Swift today). Full checklist: **`RUNTIME-TEMPLATE.md`** → section *Adding a new provider*.

**Node.js / TypeScript** reference pipeline: [`runtimes/typescript/`](./runtimes/typescript/) (`collectors/`, `adapters/`, `dev/`).

**Swift** library (Swift Package Manager): [`runtimes/swift/`](./runtimes/swift/). Add it as a dependency from an app or framework; evolve the implementation toward full parity with the TypeScript collector using [`specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md`](./specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md) and golden JSON under [`examples/`](./examples/).

---

## MVP pipeline (GlucoseAITracker / GAT)

For **Phase 1 MVP**, the **TypeScript runtime** under [`runtimes/typescript/`](./runtimes/typescript/) implements an in-process **ingestion and normalization pipeline**: adapters wrap vendor payloads in an **ingestion envelope**, the collector validates and normalizes, and output is **OGIS `glucose.reading` v0.1** validated against a pinned JSON Schema.

- **OGT (this repo)** — ingestion envelope, adapter contracts, validation orchestration, normalization code (`runtimes/typescript/collectors/`, `runtimes/typescript/adapters/`, `spec/`).
- **OGIS** — canonical event shape and semantics; authoritative schema in the **OpenGlucoseInteroperabilityStandard** (OGIS) repository. OGT pins a copy under [`spec/pinned/`](./spec/pinned/) — see [`spec/pinned/PIN.md`](./spec/pinned/PIN.md).

**Ingestion envelope schema:** [`spec/ingestion-envelope.schema.json`](./spec/ingestion-envelope.schema.json) (field descriptions: [`spec/README.md`](./spec/README.md)).

**Plans and tasks:** [`specifications/README.md`](./specifications/README.md).

### Reference implementation vs native apps (Swift, etc.)

**Node.js and TypeScript under [`runtimes/typescript/`](./runtimes/typescript/) are a portable reference implementation**, not a requirement for every OGT consumer. They exist so the pipeline can run in CI, power golden tests, and provide readable source for `submit()`-style behavior.

**OGT as a contract** is language-agnostic: the **JSON Schemas** under [`spec/`](./spec/), the **pinned OGIS** [`glucose.reading`](./spec/pinned/glucose.reading.v0_1.json) schema, **examples** under [`examples/`](./examples/), and **adapter field mappings** (e.g. [`runtimes/typescript/adapters/healthkit/README.md`](./runtimes/typescript/adapters/healthkit/README.md), [`runtimes/typescript/adapters/dexcom/README.md`](./runtimes/typescript/adapters/dexcom/README.md)) define what “OGT-compliant” ingestion means.

**Swift** adopters should use [`runtimes/swift/`](./runtimes/swift/) as the home for the Swift Package and implement collector semantics to match golden output. **Native mobile apps** often run the same steps **on device** for offline-friendly, low-latency behavior without shipping a Node runtime. Alignment is proven by **matching fixtures** (same shapes as `examples/ingestion/` → same canonical output as `examples/canonical/`) and by comparing to `pnpm pipeline` output during development. **TS ↔ Swift rule parity** (including known drift such as mmol/L factor and future-timestamp policy) is tracked in [`specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md`](./specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md); optional JSON diff: `pnpm parity:check <a.json> <b.json>` after [`examples/canonical/README.md`](./examples/canonical/README.md).

More detail for the GlucoseAITracker integration: [`specifications/handoff/OGT-GLUCOSE-009-CONSUMPTION.md`](./specifications/handoff/OGT-GLUCOSE-009-CONSUMPTION.md).

### Getting Started (MVP)

From the **repository root**:

```bash
pnpm install
pnpm build
pnpm pipeline examples/ingestion/healthkit-sample.json
pnpm pipeline examples/ingestion/dexcom-sample.json
```

Run tests: `pnpm test`. See [`runtimes/typescript/dev/README.md`](./runtimes/typescript/dev/README.md) for exit codes and the `pipeline:dev` script.

**GlucoseAITracker handoff (GLUCOSE-009):** [`specifications/handoff/OGT-GLUCOSE-009-CONSUMPTION.md`](./specifications/handoff/OGT-GLUCOSE-009-CONSUMPTION.md).

**Swift Package:** [`runtimes/swift/README.md`](./runtimes/swift/README.md), [`runtimes/swift/ARCHITECTURE.md`](./runtimes/swift/ARCHITECTURE.md) — `cd runtimes/swift && swift build && swift test`.

---

## OGT architecture

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│                    Open Glucose Telemetry (OGT) Runtime                     │
│------------------------------------------------------------------------------│
│ OGT is the runtime and transport layer for open glucose data.               │
│                                                                              │
│ It provides:                                                                 │
│ • Adapters                                                                    │
│ • Collector                                                                   │
│ • Canonical event routing                                                     │
│ • Event bus                                                                   │
│ • Query APIs                                                                  │
│ • Realtime streaming APIs                                                     │
│ • Exporters                                                                   │
│ • Replay / backfill support                                                   │
│                                                                              │
│ OGT operationalizes and transports OGIS-compliant events.                    │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Where OGT fits in the ecosystem

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│                             Consumer Systems                                 │
│------------------------------------------------------------------------------│
│ AI apps • mobile apps • dashboards • analytics • EHRs • research systems    │
└──────────────────────────────────────────────────────────────────────────────┘
                                      ▲
                                      │ consume normalized data
                                      │
┌──────────────────────────────────────────────────────────────────────────────┐
│                    Open Glucose Telemetry (OGT) Runtime                      │
│------------------------------------------------------------------------------│
│ Adapters • Collector • Event Bus • Query APIs • Streaming APIs • Exporters  │
└──────────────────────────────────────────────────────────────────────────────┘
                                      ▲
                                      │ validates and carries
                                      │ OGIS-compliant events
┌──────────────────────────────────────────────────────────────────────────────┐
│          Open Glucose Interoperability Standard (OGIS) Specification         │
│------------------------------------------------------------------------------│
│ Schemas • semantics • units • timestamps • provenance • mappings              │
└──────────────────────────────────────────────────────────────────────────────┘
                                      ▲
                                      │ standardizes data from
                                      │
┌──────────────────────────────────────────────────────────────────────────────┐
│                               Source Systems                                 │
│------------------------------------------------------------------------------│
│ CGMs • glucose meters • pumps • wearables • vendor clouds • apps              │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## How devices use OGT

Devices and vendor systems usually do not talk directly to every downstream app.

Instead, they connect into OGT through an adapter or ingestion path.

### Device flow

```text
[CGM / Meter / Pump / App / Vendor Cloud]
                  │
                  │ raw proprietary data
                  ▼
             [OGT Adapter]
                  │
                  │ translates to OGIS-compliant event
                  ▼
            [OGT Collector]
                  │
                  │ validates, normalizes, enriches
                  ▼
          [OGT Event Bus / APIs / Exporters]
```

So devices use OGT as the common runtime integration layer.

That means:

- one vendor integration can serve many apps
- one normalized pipeline can support many use cases
- one replayable event path can support real-time and historical consumption

---

## How OGT uses OGIS

OGT depends on OGIS for the meaning of the data.

**OGIS tells OGT:**

- what event types exist
- what required fields must be present
- how timestamps work
- how units must be represented
- what provenance must be preserved
- how alerts, readings, and lifecycle events are structured

**OGT then:**

- ingests source payloads
- maps them into OGIS structures
- validates them
- routes them
- exposes them to downstream systems

So the relationship is:

- **OGIS** defines the standard
- **OGT** implements the standard in motion

In simple terms:

> OGIS defines what glucose data means, and OGT defines how glucose data moves.

---

## Best mental model

Think of it like this:

- **OGIS** = the language and rules
- **OGT** = the runtime system, highways, and logistics network

Or more simply:

- **OGIS** says what a glucose event is
- **OGT** makes glucose events flow

---

## The main value of OGT

OGT creates the working operational layer that turns a paper standard into a usable platform.

**Without OGT:**

- every app has to build custom ingestion pipelines
- every vendor integration is siloed
- replay and normalization are inconsistent
- streaming and export paths vary wildly

**With OGT:**

- vendors plug into one telemetry framework
- apps consume one normalized event model
- real-time and historical data share one pipeline
- OGIS becomes practical and enforceable

---

## Full detailed architecture

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│                               Source Systems                                 │
│------------------------------------------------------------------------------│
│ CGMs • Glucose Meters • Insulin Pumps • Wearables • Vendor APIs • Mobile    │
│ Apps • CSV/File Imports • Manual Entry Systems                               │
└──────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ raw proprietary payloads
                                      ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                                OGT Adapters                                  │
│------------------------------------------------------------------------------│
│ Cloud API Adapters • BLE Adapters • File Adapters • Webhook Adapters • SDKs │
│                                                                              │
│ Responsibilities:                                                             │
│ • Authenticate with source systems                                            │
│ • Poll / receive / parse raw payloads                                       │
│ • Preserve raw source metadata                                                │
│ • Translate into OGIS-compliant events                                        │
└──────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                               OGT Collector                                  │
│------------------------------------------------------------------------------│
│ Responsibilities:                                                             │
│ • Validate against OGIS schemas                                               │
│ • Enforce semantic rules                                                      │
│ • Normalize units                                                             │
│ • Normalize timestamps                                                        │
│ • Deduplicate repeated events                                                 │
│ • Attach routing and provenance metadata                                      │
│ • Apply policy and tenant controls                                            │
└──────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                            OGT Canonical Event Bus                           │
│------------------------------------------------------------------------------│
│ Durable internal transport for OGIS-compliant events                         │
│                                                                              │
│ Capabilities:                                                                 │
│ • fan-out                                                                     │
│ • replay                                                                      │
│ • partitioning by subject/device                                              │
│ • durable delivery                                                            │
└──────────────────────────────────────────────────────────────────────────────┘
                      │                          │                         │
                      ▼                          ▼                         ▼
┌──────────────────────────────┐   ┌──────────────────────────────┐   ┌──────────────────────────────┐
│         Query APIs           │   │      Realtime Streams        │   │          Exporters           │
│------------------------------│   │------------------------------│   │------------------------------│
│ REST / GraphQL / gRPC        │   │ WebSocket / MQTT / gRPC      │   │ FHIR / Webhooks / Warehouse  │
│ Historical reads             │   │ Live subscription feeds      │   │ Research / App integrations  │
└──────────────────────────────┘   └──────────────────────────────┘   └──────────────────────────────┘
                      │                          │                         │
                      └───────────────┬──────────┴───────────────┬────────┘
                                      ▼                          ▼
                         ┌──────────────────────────┐  ┌──────────────────────────┐
                         │     Consumer Apps        │  │   Clinical / Research    │
                         │--------------------------│  │--------------------------│
                         │ AI coaching • dashboards │  │ EHRs • providers • labs  │
                         │ alerts • analytics       │  │ studies • registries     │
                         └──────────────────────────┘  └──────────────────────────┘
```

### API and export reference

**Query APIs (examples):**

- `GET /v1/subjects/{id}/glucose/readings`
- `GET /v1/subjects/{id}/glucose/latest`
- `GET /v1/subjects/{id}/alerts`

**Realtime options:** WebSocket, gRPC streaming, MQTT, webhook subscriptions.

**Exporters:** webhook, FHIR, warehouse, analytics pipelines, research datasets.

---

## Design Principles

- **Vendor-neutral** — works across all manufacturers and platforms
- **OGIS-compliant** — enforces standardized glucose semantics
- **Realtime-first** — designed for streaming but supports batch
- **Provenance-first** — all data remains traceable to its origin
- **Time-aware** — distinguishes observed, received, and processed times
- **Extensible** — supports future device types and data domains
- **Observable** — the pipeline itself is monitorable and debuggable
- **Modular** — components can be deployed independently

---

## Example canonical event

```json
{
  "event_type": "glucose.reading",
  "event_version": "1.0",
  "subject_id": "subj_123",
  "device_id": "dev_456",
  "timestamp_observed": "2026-03-28T14:32:00Z",
  "timestamp_received": "2026-03-28T14:33:15Z",
  "glucose": {
    "value": 142,
    "unit": "mg/dL"
  },
  "measurement_source": "interstitial",
  "trend": {
    "direction": "rising"
  },
  "provenance": {
    "source_vendor": "example_vendor",
    "raw_event_id": "evt_789",
    "adapter_version": "0.1.0"
  }
}
```

---

## Example end-to-end usage

### Scenario

A CGM vendor cloud produces a reading.

### Step 1: Source system emits raw data

```json
{
  "sg": 142,
  "u": "mg/dL",
  "time": "2026-03-28T15:05:00Z",
  "trendArrow": 3
}
```

### Step 2: OGT adapter receives it

The cloud adapter:

- authenticates to the vendor API
- fetches the payload
- preserves raw metadata
- converts it into an OGIS-compliant event

### Step 3: OGT collector validates it

The collector ensures:

- schema is valid
- timestamps are correct
- units are explicit
- provenance is present
- event is not duplicated

### Step 4: OGT event bus routes it

The event becomes available to:

- a live WebSocket stream
- a REST query API
- a FHIR exporter
- a webhook sink
- an analytics pipeline

### Step 5: Downstream consumers use one common interface

Apps do not need to understand that the source was Abbott, Dexcom, Libre, or a file import.

They just consume normalized data.

---

## What OGT actually contains

A clean logical breakdown for the OGT repo is:

```text
OGT
├── Adapters
│   ├── cloud
│   ├── ble
│   ├── file
│   ├── webhook
│   └── mock
├── Collector
│   ├── validation
│   ├── normalization
│   ├── deduplication
│   ├── routing
│   └── provenance
├── Event Bus
├── Query Services
├── Realtime Services
├── Exporters
│   ├── fhir
│   ├── webhook
│   ├── warehouse
│   └── app
├── SDKs
├── Replay / Backfill
└── Deployment / examples
```

Planned SDK language targets include TypeScript, Python, Swift, and Kotlin.

---

## Getting Started (Planned)

Initial setup will include:

- local collector runtime
- mock adapter
- sample event stream
- simple query API
- WebSocket streaming example

---

## Initial Roadmap

- collector core implementation
- schema validation pipeline
- adapter SDK (TypeScript)
- mock + first real adapter
- webhook exporter
- basic query API
- realtime streaming support
- local dev environment

---

## Future Capabilities

- replay service
- edge/offline sync
- alert processing
- derived metrics
- policy engine
- multi-tenant deployment
- enterprise deployment profiles

---

## Status

**Draft v0.1** — early architecture and design phase. **MVP pipeline slice** (ingestion envelope, HealthKit + mock adapters, normalization, OGIS validation, fixtures, CLI harness) lives under `runtimes/typescript/` (`collectors/`, `adapters/`, `dev/`), plus shared `spec/` and `examples/`.

---

## Vision

A world where glucose data flows through an open, real-time telemetry system instead of vendor-specific silos.

---

## Contributing

Coming soon — contributions, RFC process, and governance model will be defined in future updates.

## License

This project is licensed under the Apache License 2.0.

Apache 2.0 is a permissive open-source license that allows:

- commercial use
- modification and distribution
- private and enterprise use

It also provides an explicit patent grant from contributors to users.

This license was chosen to maximize adoption across device manufacturers,
developers, healthcare systems, and research organizations.

## Status

This project is in early development (v0.1) and is being designed in the open.

We are actively seeking feedback and collaboration from:

- device manufacturers
- developers
- healthcare organizations
- researchers
- open-source contributors