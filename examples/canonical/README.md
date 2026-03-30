# Canonical examples (`glucose.reading` v0.1)

Files here are **expected OGIS-shaped JSON** used by Vitest golden tests (see `collectors/pipeline.test.ts`). Names align with ingestion fixtures under `examples/ingestion/` (e.g. `healthkit-sample.json` → `healthkit-sample.expected.json`).

## Cross-runtime golden (TypeScript ↔ Swift)

**Goal:** The same logical reading should produce **semantically equivalent** canonical JSON whether it is processed by:

1. **This repo:** `pnpm build && pnpm pipeline path/to/envelope.json` (runs `dev/run-pipeline.js` → `submit()`), or  
2. **GlucoseAITracker:** map a `Glucose` row → `GlucoseReadingCanonical`, then serialize to JSON (test harness, manual export, or future CLI).

**Process**

1. Pick or author an ingestion envelope under `examples/ingestion/` (or an app-native row that maps to the same fields).
2. Run the **TS reference** and capture stdout JSON (or use the matching `*.expected.json` in this folder).
3. Produce **Swift-derived** JSON from the app (unit test `Codable` encode, or hand export).
4. Compare:
   - **Strict:** Use `pnpm parity:check <file-a.json> <file-b.json>` (stable JSON comparison).
   - **Semantic:** Allow known drift from the [parity matrix](../../specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md) (e.g. mmol/L factor **18.0** vs **18.018**, missing future-timestamp rejection on Swift).

**Checked-in samples**

| File | Provenance |
|------|------------|
| `healthkit-sample.expected.json` | Golden output for `examples/ingestion/healthkit-sample.json` (TS pipeline). |
| `dexcom-sample.expected.json` | Golden output for `examples/ingestion/dexcom-sample.json` (TS pipeline). |
| `manual-sample.swift-export.json` | **Hand-synced 2026-03-29** to match TS `pnpm pipeline examples/ingestion/healthkit-sample.json` output for parity documentation (same content as `healthkit-sample.expected.json` at time of sync). Replace when Swift export diverges intentionally. |

CI on Linux cannot run Xcode; **optional** future job: diff TS pipeline output against a Swift-exported file on a macOS runner, or refresh `manual-sample.swift-export.json` manually after Swift changes.
