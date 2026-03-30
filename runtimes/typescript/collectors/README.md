# Collectors (TypeScript)

**Package overview:** [`../README.md`](../README.md) · **Architecture diagrams:** [`../ARCHITECTURE.md`](../ARCHITECTURE.md)

The collector is the in-process pipeline that runs **after** wire ingestion: **envelope validation** → **per-source validate + map** (registry) → **normalization** → **semantic rules** → **optional dedupe** → **OGIS JSON Schema** check — parity with Swift `OGTCollectorEngine.run` and [`core/collector-engine.ts`](./core/collector-engine.ts).

## Layout (mirrors Swift `collectors/`)

| Subfolder | Role |
|-----------|------|
| **`core/`** | **`collector-engine.ts`** — `submit()` + `finalize()` (main entry). **`pipeline-result.ts`** — `PipelineResult`, `StructuredPipelineError`, issue codes. **`submit-options.ts`** — `SubmitOptions` (`dedupe`). |
| **`ingestion/`** | **`ingestion-types.ts`** — `IngestionEnvelope` wire shape. |
| **`registry/`** | **`ingest-plugins.ts`** — `builtinIngestPlugins` (per-source validate + map). **Do not** add `if (source)` branches to the engine; append plugins here. |
| **`canonical/`** | **`canonical-glucose-reading.ts`** — `CanonicalGlucoseReadingV01` type. |
| **`validation/`** | **`schema-validators.ts`** — Ajv: envelope, per-source payloads, pinned OGIS `glucose.reading`. **`semantic.ts`** — `applySemanticRules`. |
| **`normalization/`** | **`normalize.ts`** — `normalizeCanonicalReading`, timestamps, mg/dL. **`dedupe.ts`** — `DedupeTracker`. |
| **`tooling/`** | **`paths.ts`** — `specPaths.repoRoot` and schema paths (validators, tests). **`schema-load.ts`** — read JSON Schema files. |

**Public barrel:** [`pipeline.ts`](./pipeline.ts) re-exports `submit`, types, and `DedupeTracker` for a stable import path (`import { submit } from "./collectors/pipeline.js"`).

## Flow

`submit(envelope, options?)` looks up **`builtinIngestPlugins[env.source]`**, runs payload validation and `mapToCanonical`, then **`finalize`**: normalize → semantic → optional dedupe → OGIS validation.

## Other language ports (Swift, Kotlin, …)

Mirror this stage order and validate against [`spec/pinned/`](../../../spec/pinned/) and golden JSON under [`examples/`](../../../examples/). See [`specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md`](../../../specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md) and [`examples/canonical/README.md`](../../../examples/canonical/README.md).
