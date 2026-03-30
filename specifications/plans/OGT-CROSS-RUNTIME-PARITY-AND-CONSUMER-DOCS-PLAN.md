# OGT — Cross-runtime parity & consumer documentation (GlucoseAITracker wave 2)

**Audience:** OGT maintainers, GlucoseAITracker (GLUCOSE-009) implementers, anyone porting the collector to another language  
**Scope:** Close the loop between the **TypeScript reference pipeline** and the **in-app Swift subset**, and document the **consumer pattern** (persist native row → derive OGIS → semantic gate) so both repos gain durable value.  
**Non-goals:** Embedding Swift in OGT CI, rewriting the iOS app in TypeScript, or changing OGIS schema v0.1 (schema work lives in OGIS; this plan references outcomes).

---

## Problem statement

GlucoseAITracker implements **OGT-style** validation and **OGIS**-shaped canonical readings **on device** (`OGTGlucoseIngestPipeline`, `GlucoseReadingCanonicalMapper`). The OGT repository remains the **regression oracle** for the TypeScript collector (`runtimes/typescript/collectors/pipeline.ts`, `runtimes/typescript/collectors/semantic.ts`, `runtimes/typescript/collectors/normalize.ts`).

Today:

- There is **no single checklist** of rule-by-rule parity (future clock skew, mmol/L factor, empty-string provenance, etc.).
- **Golden JSON** is produced and tested in TS; Swift paths are tested in Xcode separately—**cross-repo fixtures** are optional, not systematic.
- [OGT-GLUCOSE-009-CONSUMPTION.md](../handoff/OGT-GLUCOSE-009-CONSUMPTION.md) describes handoff but not the **two-stage persistence** pattern in depth (native `Glucose` vs derived canonical).

Delivering this plan **reduces silent drift**, makes contributions from mobile **first-class**, and gives OGT clearer **documentation value** independent of shipping a bus or APIs.

---

## Goals

1. **Parity matrix** — Document TS vs Swift behavior for each semantic and structural check relevant to `glucose.reading` v0.1 ingest, with explicit **“intentional difference”** callouts and owners.
2. **mmol/L ↔ mg/dL** — Align implementations with **OGIS [unit-semantics.md](https://github.com/peterlandis/OpenGlucoseInteroperabilityStandard/blob/main/spec/core/unit-semantics.md)** (factor **18.018**) or record **normative exceptions** in both OGT and GlucoseAITracker with the same wording.
3. **Future timestamp policy** — Either document that Swift omits **15-minute skew** (`FUTURE_SKEW_MS` in `runtimes/typescript/collectors/semantic.ts`) or add equivalent policy to Swift and note it in the matrix.
4. **Shared golden artifacts (optional CI)** — At minimum: **documented process** to export canonical JSON from Swift (or hand-maintain) under `examples/canonical/` with a **parity note**; stretch: CI job that `diff`s TS pipeline output vs checked-in Swift-exported file for one fixture.
5. **Consumer documentation in OGT** — Extend handoff / README with **two-stage adaptation** summary and link to GlucoseAITracker’s [OGT-OGIS-INTEGRATION.md](https://github.com/peterlandis/GlucoseAITracker/blob/main/Documentation/OGT-OGIS-INTEGRATION.md) (path when repos are siblings: `../GlucoseAITracker/Documentation/OGT-OGIS-INTEGRATION.md`).

---

## Relationship to OGIS

| Topic | Owner |
|--------|--------|
| Exact conversion factor mg/dL ↔ mmol/L, normative text | **OGIS** `spec/core/unit-semantics.md` |
| Whether clinical range checks apply before or after normalization | **OGIS** informative + **OGT** semantic policy |
| JSON Schema for `glucose.reading` | **OGIS**; OGT pins copy under `spec/pinned/` |

This OGT plan **implements** alignment in TS and **tracks** Swift parity; OGIS may receive small doc clarifications under its own plan ([OGIS-IMPLEMENTER-INTEROP-GUIDANCE-PLAN.md](../../../OpenGlucoseInteroperabilityStandard/specifications/plans/OGIS-IMPLEMENTER-INTEROP-GUIDANCE-PLAN.md) when both repos are co-located).

---

## Deliverables

| # | Deliverable | Location |
|---|-------------|----------|
| D1 | Parity matrix markdown | `specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md` (new) |
| D2 | Updated handoff: two-stage consumer + links | `specifications/handoff/OGT-GLUCOSE-009-CONSUMPTION.md` |
| D3 | Optional: Swift-sourced or hand-synced canonical JSON + README note | `examples/canonical/` |
| D4 | TS code or tests only if matrix requires behavior change | `runtimes/typescript/collectors/normalize.ts`, `runtimes/typescript/collectors/semantic.ts`, tests |
| D5 | Completion summary (when wave closes) | `specifications/summary/OGT-CROSS-RUNTIME-PARITY-COMPLETION-SUMMARY.md` |

---

## Success criteria

- A new reader can open **D1** and know whether TS and Swift match on **event envelope**, **provenance strings**, **numeric range**, **unit conversion**, and **timestamp policy**.
- OGIS **18.018** is either used consistently in both runtimes or **explicitly waived** in OGIS/OGT/GlucoseAITracker docs with the same rationale.
- **FEATURES.md** rows **PAR-001**, **PAR-002**, **DOC-005** reflect **✅ Complete** when this wave is done (see task file for IDs).

---

## Risks

- **CI without macOS:** Full Swift execution in OGT GitHub Actions may be unavailable; prefer **checked-in JSON** and manual or GlucoseAITracker-repo CI for Swift export.
- **Scope creep:** Do not expand into new vendor adapters here—only parity and documentation unless a parity fix requires a one-line TS change.

---

## Suggested implementation order

1. Author **D1** from current code inspection (TS + Swift side-by-side).  
2. Decide **18.018 vs 18.0** with OGIS task alignment.  
3. Implement TS or Swift fixes **or** document waivers.  
4. Update **D2**; add **D3** if valuable.  
5. Write **D5** and flip feature statuses.

---

**Last updated:** 2026-03-30
