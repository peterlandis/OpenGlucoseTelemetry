# OGT — Cross-runtime parity & consumer documentation — completion summary

**Plan:** [OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-PLAN.md](../plans/OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-PLAN.md)  
**Tasks:** [OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-TASKS.md](../tasks/OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-TASKS.md)  
**Branch / delivery:** `feature/OGT-cross-runtime-parity-consumer-docs` (merge to default when reviewed).

## What shipped

| Deliverable | Location |
|-------------|----------|
| Parity matrix (D1) | `specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md` |
| Handoff + consumer pattern (D2) | `specifications/handoff/OGT-GLUCOSE-009-CONSUMPTION.md` |
| Canonical / golden process + sample (D3) | `examples/canonical/README.md`, `examples/canonical/manual-sample.swift-export.json` |
| Parity JSON check (stretch) | `runtimes/typescript/dev/parity-check.mjs`, `pnpm parity:check` in root `package.json` |
| Port guidance (D2/D3 overlap) | `runtimes/typescript/collectors/README.md` (“Other language ports”), root `README.md` links |
| Vitest guard for OGIS factor (A-03, no TS behavior change) | `runtimes/typescript/collectors/normalize.test.ts` |
| Feature rows (D5) | `FEATURES.md` — PAR-001, PAR-002, DOC-005 → **Complete** |

## Decisions

1. **mmol/L factor:** TypeScript already uses **`MGDL_PER_MMOL = 18.018`** per OGIS unit-semantics. **GlucoseAITracker** still uses **18.0** in `OGTGlucoseIngestPipeline` and `GlucoseReadingCanonicalMapper` — documented as **intentional drift** pending an app PR; no TS change required.
2. **Future timestamp skew:** TS enforces **15 minutes** (`FUTURE_SKEW_MS` in `runtimes/typescript/collectors/validation/semantic.ts`). Swift **omits** this check — documented as **Waived** in the parity matrix with rationale (on-device / backfill semantics).
3. **Full Ajv in Swift:** Out of scope for GAT; matrix records **subset** validation in-app vs full schema in TS.

## Residual drift / follow-ups

- **GlucoseAITracker:** Replace **18.0** with **18.018** (and audit `UserSettings` / `InsightGlucoseReading` conversion helpers) for numeric parity with OGT/OGIS.
- **Optional:** macOS CI job to export Swift JSON and `pnpm parity:check` against TS golden.
- **Optional:** Align optional device string trimming with `boundOptionalString` if wire exports must match key omission exactly.

---

**Last updated:** 2026-03-29
