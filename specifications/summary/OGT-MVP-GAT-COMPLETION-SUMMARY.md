# OGT MVP (GAT) — Completion summary

**Feature slice:** GlucoseAITracker integration — ingestion envelope, in-process collector pipeline, OGIS `glucose.reading` v0.1 output  
**Plan:** [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](../plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md)  
**Tasks:** [OGT-MVP-IMPLEMENTATION-TASKS.md](../tasks/OGT-MVP-IMPLEMENTATION-TASKS.md) (all items checked for GAT scope)  
**Feature tracking:** [FEATURES.md](../../FEATURES.md)  
**Date:** 2026-03-29

---

## Executive summary

The Open Glucose Telemetry repository now includes a **portable TypeScript MVP pipeline** under **`runtimes/typescript/`** that accepts **ingestion envelopes** from adapters, validates envelope and per-source payloads, maps **HealthKit-shaped**, **Dexcom EGV-style**, and **mock** JSON payloads to a pre-canonical reading, **normalizes** timestamps (UTC, millisecond precision) and glucose **to mg/dL** per GAT policy, applies **semantic gates** (plausible mg/dL range, future `observed_at` skew), optionally **dedupes** in memory, and validates the result against a **pinned OGIS** `glucose.reading` v0.1 JSON Schema. **Golden and negative fixtures**, a **`runtimes/typescript/dev/` CLI**, **`pnpm verify`** from the repo root (build + tests + smoke), and **GitHub Actions** provide reproducible behavior without an iPhone. **Non-goals** for this slice remain unchanged: durable bus, REST/WebSocket APIs, webhook exporter, full compose stack.

---

## Deliverables completed

### Repository layout

| Path | Purpose |
|------|---------|
| `runtimes/typescript/collectors/` | `core/collector-engine.ts` (`submit`), `registry/ingest-plugins`, `validation/schema-validators`, `normalization`, Vitest tests |
| `runtimes/typescript/adapters/healthkit/`, `runtimes/typescript/adapters/dexcom/`, `runtimes/typescript/adapters/mock/` | Source mappers + field mapping docs |
| `spec/ingestion-envelope.schema.json` | Normative ingestion envelope (Draft 2020-12) |
| `spec/healthkit-payload.schema.json` | Serializable HK glucose sample shape |
| `spec/dexcom-payload.schema.json` | Serializable Dexcom EGV-style payload |
| `spec/mock-payload.schema.json` | Mock adapter payload |
| `spec/pinned/glucose.reading.v0_1.json` | Pinned OGIS canonical schema (checksum in `spec/pinned/PIN.md`) |
| `spec/README.md` | Envelope and payload documentation |
| `examples/ingestion/` | Positive + negative envelopes |
| `examples/canonical/*-sample.expected.json` | Golden expected `glucose.reading` outputs (HealthKit, Dexcom, …) |
| `runtimes/typescript/dev/run-pipeline.ts` | CLI: JSON file → stdout canonical or stderr structured error |
| `specifications/handoff/` | GLUCOSE-009 consumption + version compatibility |

### Pipeline behavior (high level)

```text
IngestionEnvelope
  → validate envelope (JSON Schema)
  → route by source (healthkit | dexcom | mock)
  → validate payload (per-source schema)
  → map to pre-canonical glucose.reading fields
  → normalize (time, unit → mg/dL, string bounds, strip nulls)
  → semantic rules
  → [optional] dedupe key
  → validate OGIS glucose.reading v0.1 (JSON Schema)
  → Result<CanonicalReading, StructuredError>
```

Structured errors: `{ code, message, field?, trace_id }` with stable `code` values for logging (`ENVELOPE_INVALID`, `PAYLOAD_INVALID`, `ADAPTER_UNKNOWN`, `MAPPING_FAILED`, `SEMANTIC_INVALID`, `CANONICAL_SCHEMA_INVALID`, `DUPLICATE_EVENT`).

### Tooling and CI

| Item | Purpose |
|------|---------|
| Root `package.json` + `pnpm-workspace.yaml` | Workspace scripts: `pnpm build`, `pnpm test`, `pnpm pipeline`, `pnpm verify` |
| `runtimes/typescript/tsconfig.build.json` | Emits `runtimes/typescript/dist/` for Node CLI (no tsx required at runtime) |
| `.github/workflows/ogt-mvp-ci.yml` | `pnpm install --frozen-lockfile` + `pnpm verify` on push/PR |

### Documentation

- **README.md:** MVP (GAT) section — getting started, links to `spec/` and specifications index.
- **FEATURES.md:** GAT-scoped feature IDs marked **Complete** where implemented; `PLAT-002` notes GAT vs Next split.
- **Handoff:** [OGT-GLUCOSE-009-CONSUMPTION.md](../handoff/OGT-GLUCOSE-009-CONSUMPTION.md), [VERSION-COMPATIBILITY.md](../handoff/VERSION-COMPATIBILITY.md).

---

## Traceability

| Feature IDs (GAT) | OGT implementation notes |
|-------------------|-------------------------|
| OGIS-001, OGIS-002 | Pinned schema + Ajv validation after map/normalize |
| COL-001 — COL-005 | Envelope, gates, normalization, optional dedupe, provenance/trace |
| ADP-001, ADP-006, ADP-007 | Mock + HealthKit + Dexcom fixture mappers |
| DEV-003 | `runtimes/typescript/dev/run-pipeline.ts` + `runtimes/typescript/dev/README.md` |
| QA-001 | Golden + negative tests + CI smoke |

Explicitly **not** in this summary (still **Next** / **Later** in [FEATURES.md](../../FEATURES.md)): BUS-*, QRY-*, RT-001, EXP-*, full SDK-001 package, DEV-001 compose, QA-002 bus→query integration.

---

## Upstream and downstream

- **OGIS:** Authoritative semantics and schema revisions live in **OpenGlucoseInteroperabilityStandard**; OGT records SHA in `spec/pinned/PIN.md` when pinning updates.
- **GlucoseAITracker:** Integrate per **GLUCOSE-009**; parity via same fixture shapes and comparison to `pnpm pipeline` output (see handoff doc).

---

## Suggested next steps

1. Merge the integration branch to the default branch when review is complete.
2. Port or embed the pipeline in **GlucoseAITracker** behind the feature flag; run golden parity checks.
3. Prioritize **Next** rows (bus, query, published SDK) per product roadmap.

---

## Document history

| Date | Change |
|------|--------|
| 2026-03-29 | Initial GAT MVP completion summary |
| 2026-03-29 | Dexcom fixture adapter (`source: dexcom`), schema, golden example |
