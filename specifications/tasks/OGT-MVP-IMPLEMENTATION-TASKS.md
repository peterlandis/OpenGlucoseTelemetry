# OGT MVP — Implementation Tasks (GlucoseAITracker integration)

Companion to [OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md](../plans/OGT-MVP-GLUCOSEAITRACKER-PIPELINE-PLAN.md).

**Legend:** `[ ]` open · `[x]` done

---

## Track O — Repository and documentation

- [x] **OGT-MVP-O-01** Create directory scaffold: `collectors/`, `adapters/`, `spec/`, `examples/`, `dev/` (placeholder README in each).
- [x] **OGT-MVP-O-02** Add `specifications/plans` and `specifications/tasks` index or link from root `README.md`.
- [x] **OGT-MVP-O-03** Update root `README.md` with MVP subsection: OGT vs OGIS, link to OGIS repo, link to ingestion envelope schema.
- [x] **OGT-MVP-O-04** Pin OGIS v0.1 dependency strategy (submodule, npm/git dependency, or copy `glucose.reading` schema with version file + SHA note).

---

## Track E — Ingestion envelope

- [x] **OGT-MVP-E-01** Author JSON Schema for ingestion envelope (`spec/ingestion-envelope.schema.json`).
- [x] **OGT-MVP-E-02** Document envelope fields in `spec/README.md` (table + examples).
- [x] **OGT-MVP-E-03** Implement envelope parser + validator returning structured errors.

---

## Track V — Validation (collector)

- [x] **OGT-MVP-V-01** Implement OGIS canonical validation step using pinned `glucose.reading` JSON Schema from OGIS.
- [x] **OGT-MVP-V-02** Implement semantic rules: required fields, numeric range, unit whitelist, timestamp sanity (per OGIS time doc).
- [x] **OGT-MVP-V-03** Add JSON Schema for `source=healthkit` `payload` (serializable HK sample).
- [x] **OGT-MVP-V-04** Unit tests: each rejection path returns stable `code` suitable for logging.

---

## Track N — Normalization

- [x] **OGT-MVP-N-01** Timestamp normalization (UTC, precision, future-date policy per OGIS).
- [x] **OGT-MVP-N-02** Unit normalization per OGIS v0.1 policy (single canonical unit vs dual fields).
- [x] **OGT-MVP-N-03** Light cleanup (types, null stripping, string bounds).
- [x] **OGT-MVP-N-04** Unit tests for edge cases (DST boundaries, mmol/L vs mg/dL inputs).

---

## Track A — Adapters

- [x] **OGT-MVP-A-01** **Mock adapter:** generates valid envelope + minimal payload → known canonical output (for pipeline integration test).
- [x] **OGT-MVP-A-02** **HealthKit adapter:** map fixture `payload` → OGIS `glucose.reading` (including `device`, `provenance`, `measurement_source` best-effort).
- [x] **OGT-MVP-A-03** Document mapping table: HK JSON field → OGIS field (markdown under `adapters/healthkit/README.md`).
- [x] **OGT-MVP-A-04** (Optional) Swift package or GlucoseAITracker bridge doc: live `HKQuantitySample` → same JSON `payload` shape as fixtures.

---

## Track M — Mapping orchestration (“collector pipeline”)

- [x] **OGT-MVP-M-01** Implement `submit(envelope) -> Result<CanonicalGlucoseReading, PipelineError>` (name as appropriate for chosen language).
- [x] **OGT-MVP-M-02** Wire order: parse envelope → adapter route by `source` → map to canonical → normalize → validate.
- [x] **OGT-MVP-M-03** (Optional MVP) In-memory dedupe key: `(subject_id, observed_at, raw_event_id)` or hash of payload — document idempotency expectations.

---

## Track F — Fixtures and tests

- [x] **OGT-MVP-F-01** Add `examples/ingestion/healthkit-sample.json` and `examples/canonical/healthkit-sample.expected.json`.
- [x] **OGT-MVP-F-02** Add negative fixtures (bad unit, missing `observed_at`, out-of-range value).
- [x] **OGT-MVP-F-03** Golden test: fixture pair passes pipeline and matches expected canonical document (semantic JSON compare).
- [x] **OGT-MVP-F-04** CI workflow: install deps, run tests, run harness on sample (smoke).

---

## Track D — Dev harness

- [x] **OGT-MVP-D-01** Implement CLI/script under `dev/` (see plan §9).
- [x] **OGT-MVP-D-02** `dev/README.md`: prerequisites, run command, exit codes.
- [x] **OGT-MVP-D-03** Root README “Getting Started (MVP)” one-liner for harness.

---

## Track G — GlucoseAITracker handoff

- [x] **OGT-MVP-G-01** Document how GLUCOSE-009 consumes OGT: same types, JSON round-trip, or shared Swift module (decision record).
- [x] **OGT-MVP-G-02** List version compatibility: OGT release ↔ OGIS schema version ↔ GlucoseAITracker min version.
- [x] **OGT-MVP-G-03** Document **feature flag** behavior: GlucoseAITracker runs legacy vs OGT ingestion per flag; insights always use canonical inputs (legacy bridge when flag off). Cross-link GlucoseAITracker plan `specifications/plans/GLUCOSE-009-OGT-OGIS-INTEGRATION-PLAN.md` when repos are co-located.
- [x] **OGT-MVP-G-04** Add QA note: compare golden fixture output to on-device OGT path with flag **on** for HealthKit-shaped samples.

---

## Suggested order

1. O-01 → O-04, E-01 → E-03  
2. OGIS schema available (OGIS repo tasks) → V-01 → V-02  
3. N-01 → N-04  
4. A-01 → M-01 → M-02 → F-01 → F-03  
5. A-02 → A-03 → F-01/F-02 extension → D-01 → D-03  
6. G-01 → G-04  

---

## Related — wave 2 (cross-runtime parity & consumer docs)

- Plan: [OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-PLAN.md](../plans/OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-PLAN.md)
- Tasks: [OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-TASKS.md](./OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-TASKS.md)
- OGIS companion: [OGIS-IMPLEMENTER-INTEROP-GUIDANCE-PLAN.md](../../../OpenGlucoseInteroperabilityStandard/specifications/plans/OGIS-IMPLEMENTER-INTEROP-GUIDANCE-PLAN.md) (sibling repo)

---

**Last updated:** 2026-03-29 — MVP pipeline implemented in-repo; all tracks marked complete for GAT scope.
