# OGT — Cross-runtime parity & consumer documentation — Implementation tasks

Companion to [OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-PLAN.md](../plans/OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-PLAN.md).

**Legend:** `[ ]` open · `[x]` done

---

## Track P — Parity matrix

- [x] **OGT-PAR-P-01** Create `specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md` with a table: **Rule** | **TS location** | **Swift location** | **Match?** | **Notes / owner**.
- [x] **OGT-PAR-P-02** Document **event_type** / **event_version** enforcement (`runtimes/typescript/collectors/` + schema validation vs Swift `OGTGlucoseIngestPipeline`).
- [x] **OGT-PAR-P-03** Document **empty** `subject_id`, `raw_event_id`, `source_system`, `adapter_version` handling.
- [x] **OGT-PAR-P-04** Document **value > 0** and **20–600 mg/dL equivalent** rules (including mmol/L path).
- [x] **OGT-PAR-P-05** Document **future timestamp** policy: `FUTURE_SKEW_MS` in `runtimes/typescript/collectors/validation/semantic.ts` vs Swift (currently may be absent).
- [x] **OGT-PAR-P-06** Document **mmol/L ↔ mg/dL** factor: TS `MGDL_PER_MMOL` (18.018) vs Swift (`18.0` today) vs OGIS `unit-semantics.md`.

---

## Track A — Alignment fixes (as decided from matrix)

- [x] **OGT-PAR-A-01** If OGIS normative factor is **18.018**: update TS only if already wrong; track Swift change in GlucoseAITracker repo (separate PR). *(TS already 18.018; Swift drift documented in matrix + completion summary.)*
- [x] **OGT-PAR-A-02** If Swift should match **future skew**: either add Swift tests documenting omission or open GlucoseAITracker issue; update matrix **Waived** row with rationale. *(Matrix **Waived** rows + summary.)*
- [x] **OGT-PAR-A-03** Add or extend **Vitest** cases for any TS behavior change from A-01. *(No TS change; added `runtimes/typescript/collectors/normalize.test.ts` for regression on **18.018**.)*

---

## Track F — Fixtures & optional cross-check

- [x] **OGT-PAR-F-01** Add `examples/canonical/README.md` subsection: **Cross-runtime golden** — how TS `pnpm pipeline` output should relate to Swift-derived JSON.
- [x] **OGT-PAR-F-02** (Optional) Add one fixture e.g. `examples/canonical/manual-sample.swift-export.json` with provenance comment “exported from GlucoseAITracker test …” or “hand-synced on DATE”.
- [x] **OGT-PAR-F-03** (Optional) Script or `package.json` target: `pnpm parity:check` comparing two JSON files (document-only if no automation).

---

## Track D — Documentation / handoff

- [x] **OGT-PAR-D-01** Update `specifications/handoff/OGT-GLUCOSE-009-CONSUMPTION.md`: link **OGT-SWIFT-PARITY-MATRIX.md**, summarize **native row → OGIS → semantic gate**, link GlucoseAITracker **OGT-OGIS-INTEGRATION.md**.
- [x] **OGT-PAR-D-02** Update root `README.md` or `runtimes/typescript/collectors/README.md` with one paragraph: **Other language ports** — start from parity matrix + pinned schema.
- [x] **OGT-PAR-D-03** Update [FEATURES.md](../../FEATURES.md) statuses for **PAR-001**, **PAR-002**, **DOC-005** when complete.

---

## Track S — Summary

- [x] **OGT-PAR-S-01** Add `specifications/summary/OGT-CROSS-RUNTIME-PARITY-COMPLETION-SUMMARY.md` when the wave ships (decisions, residual drift, follow-ups).

---

## Suggested order

P-01 → P-02 … P-06 → A-01 … A-03 (as needed) → D-01 → D-02 → F-01 → (F-02, F-03) → S-01 → D-03

---

**Last updated:** 2026-03-29 (wave complete on branch `feature/OGT-cross-runtime-parity-consumer-docs`)
