# Collectors (MVP)

In-process pipeline: **envelope validation** → **adapter routing** → **normalization** → **semantic checks** → **OGIS JSON Schema** validation.

Entry point: `submit()` in `pipeline.ts`. Structured errors use `{ code, message, field?, trace_id }`.

Optional **dedupe**: pass `DedupeTracker` in `submit` options; duplicates return `DUPLICATE_EVENT`.
