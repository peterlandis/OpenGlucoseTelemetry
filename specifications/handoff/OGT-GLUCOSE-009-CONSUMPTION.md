# GlucoseAITracker (GLUCOSE-009) — consuming OGT

**Parity & drift:** Rule-by-rule TS vs Swift alignment lives in **[OGT-SWIFT-PARITY-MATRIX.md](./OGT-SWIFT-PARITY-MATRIX.md)**. Canonical golden workflow: [`examples/canonical/README.md`](../../examples/canonical/README.md).

## Decision (G-01)

- **Reference implementation:** TypeScript in this repository (`collectors/pipeline.ts`, `submit()`), validated by golden JSON fixtures and CI.
- **App integration options:**
  1. **Port** the pipeline to Swift and keep behavioral parity with the same fixtures, or
  2. **JSON round-trip:** build the ingestion envelope + HealthKit payload JSON in Swift, call a small helper that runs the TS pipeline (e.g. dev tool / test host only), or embed logic duplicated from the port.

Production apps typically choose a **Swift port** for latency and offline use; the TS repo remains the contract and regression oracle.

## Version matrix (G-02)

See [VERSION-COMPATIBILITY.md](./VERSION-COMPATIBILITY.md).

## Feature flag and insights (G-03)

Cross-link: GlucoseAITracker plan (when checked out as a **sibling** of this repository, e.g. under the same workspace folder):

`../GlucoseAITracker/specifications/plans/GLUCOSE-009-OGT-OGIS-INTEGRATION-PLAN.md` (relative to the **OpenGlucoseTelemetry** repo root).

Expected behavior:

- **Feature flag** (e.g. `UserDefaults`, default off): selects **legacy ingestion** vs **OGT pipeline** for writes/sync.
- **Insights engine:** consumes **OGIS-aligned canonical readings** only. With the flag off, a **legacy bridge** maps existing Core Data / `Glucose` rows into the same canonical shape so insight code is not forked.

## QA (G-04)

With the flag **on**, for HealthKit-shaped samples:

1. Build the same JSON payload as `examples/ingestion/healthkit-sample.json` (structure, not necessarily identical values).
2. Run through the in-app pipeline and compare the resulting `glucose.reading` document to `pnpm pipeline <envelope.json>` output from this repo (semantic JSON equality).

Record any intentional product differences in adapter notes.

## Consumer pattern — native row vs canonical (G-05)

**Summary:** Persist the **native** row (**`Glucose`**, Core Data) as today. For OGT/OGIS alignment, **derive** **`GlucoseReadingCanonical`** (OGIS `glucose.reading` v0.1) via **`GlucoseReadingCanonicalMapper`**, then run **`OGTGlucoseIngestPipeline.validate`** (semantic / schema-ish gate) before relying on that reading for ingest filtering or insights. This is **not** a second persisted table in the current GAT design—canonical is an **interoperability projection** of the native row.

Full narrative, diagrams, and extension points:

- `../GlucoseAITracker/Documentation/OGT-OGIS-TWO-STAGE-ADAPTATION.md` (sibling checkout)

This OGT repository defines the **TypeScript** reference pipeline; the Swift path is a **documented subset** (see matrix). Supporting artifacts:

- Plan: [OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-PLAN.md](../plans/OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-PLAN.md)
- Tasks: [OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-TASKS.md](../tasks/OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-TASKS.md)
- Parity matrix: [OGT-SWIFT-PARITY-MATRIX.md](./OGT-SWIFT-PARITY-MATRIX.md)

**OGIS** informative guidance (**`source_system` registry**, time wire notes) ships under [OpenGlucoseInteroperabilityStandard](https://github.com/peterlandis/OpenGlucoseInteroperabilityStandard): [OGIS-IMPLEMENTER-INTEROP-GUIDANCE-PLAN.md](../../../OpenGlucoseInteroperabilityStandard/specifications/plans/OGIS-IMPLEMENTER-INTEROP-GUIDANCE-PLAN.md) when repos are siblings.
