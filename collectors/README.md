# Collectors (MVP)

In-process pipeline: **envelope validation** → **adapter routing** → **normalization** → **semantic checks** → **OGIS JSON Schema** validation.

Entry point: `submit()` in `pipeline.ts`. Structured errors use `{ code, message, field?, trace_id }`.

Optional **dedupe**: pass `DedupeTracker` in `submit` options; duplicates return `DUPLICATE_EVENT`.

## Other language ports (Swift, Kotlin, …)

If you are **not** embedding Node, treat this folder plus [`spec/pinned/`](../spec/pinned/) as the behavioral spec: mirror `normalizeCanonicalReading` and `applySemanticRules`, then validate output against the pinned **`glucose.reading` v0.1** JSON Schema (or an equivalent rule set). Start from the **TS ↔ Swift parity matrix** — [`specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md`](../specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md) — so intentional differences (units, future-clock policy, optional fields) are explicit before you ship a port. Golden JSON workflow: [`examples/canonical/README.md`](../examples/canonical/README.md) and `pnpm parity:check`.
