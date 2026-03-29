# GlucoseAITracker (GLUCOSE-009) — consuming OGT

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
