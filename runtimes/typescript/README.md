# Open Glucose Telemetry — TypeScript runtime

npm package **`@openglucose/telemetry-mvp`** (private workspace member): reference implementation with shared **`collectors/`** (orchestration) and **`adapters/`** (per-source mapping). Other runtimes (e.g. [`../swift`](../swift)) mirror this layout and behavior.

Shared contracts (schemas, fixtures) live at the repo root: [`../../spec`](../../spec), [`../../examples`](../../examples). Parity expectations: [`../../specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md`](../../specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md).

---

## Architecture (this package)

**Collectors** implement the full **ingestion pipeline** in **`submit()`** ([`collectors/core/collector-engine.ts`](./collectors/core/collector-engine.ts), re-exported from [`collectors/pipeline.ts`](./collectors/pipeline.ts)): **Ajv** validates the envelope and each per-source payload, then **`adapters/*/map.ts`** map to **`CanonicalGlucoseReadingV01`**, then **`normalizeCanonicalReading`**, **`applySemanticRules`**, optional **`DedupeTracker`**, and **Ajv** validation against the pinned OGIS **`glucose.reading`** schema.

**Adapters** live under **`adapters/<source>/`** (`healthkit`, `dexcom`, `mock`). Each **`map*PayloadToCanonical`** turns the envelope **`payload`** into canonical fields **before** normalization (same role as Swift **`OGTSourceAdapter.mapPayload`**).

**Routing:** **`builtinIngestPlugins[source]`** in [`collectors/registry/ingest-plugins.ts`](./collectors/registry/ingest-plugins.ts) — **no** growing `if (source)` list in **`submit()`**. Add a source by registering a plugin and adding validators in [`collectors/validation/schema-validators.ts`](./collectors/validation/schema-validators.ts).

```text
unknown JSON (ingestion envelope)
  → validateEnvelope (Ajv / ingestion-envelope.schema.json)
  → submit(envelope, options?)
  → builtinIngestPlugins[source]: validatePayload + mapToCanonical
  → finalize: normalizeCanonicalReading, applySemanticRules, optional dedupe
  → validateGlucoseReadingOgis (Ajv)
  → PipelineResult { ok: true, value } | { ok: false, error: StructuredPipelineError }
```

**Optional:** pass **`SubmitOptions`** with **`dedupe`** (in-memory dedupe; duplicates → **`DUPLICATE_EVENT`**).

**Tooling paths:** **`specPaths`** in [`collectors/tooling/paths.ts`](./collectors/tooling/paths.ts) locates the repo root and schema file paths (used by validators and tests)—it is **not** part of the app ingest path. **`dev/run-pipeline.ts`** is a small CLI that reads a JSON file and prints **`submit`** output.

More detail: **[`collectors/README.md`](./collectors/README.md)** (MVP notes, ports), **[`ARCHITECTURE.md`](./ARCHITECTURE.md)** (folder layout, flow diagrams).

---

## Tests: what they exercise

Main suite: **[`collectors/pipeline.test.ts`](./collectors/pipeline.test.ts)** (Vitest).

| Test / group | What it shows |
|----------------|----------------|
| **`passes healthkit golden fixture`** | Repo **`examples/ingestion/healthkit-sample.json`** → **`submit`** → normalized output matches **`examples/canonical/healthkit-sample.expected.json`**. |
| **`passes dexcom golden fixture`** | Same pattern for Dexcom sample + expected canonical JSON. |
| **`passes mock adapter envelope`** | Inline mock envelope → **`submit`** → mg/dL normalization and **`measurement_source`**. |
| **`rejects unknown adapter source`** | **`ADAPTER_UNKNOWN`** and stable **`trace_id`**. |
| **`rejects invalid envelope` / bad healthkit payload** | **`ENVELOPE_INVALID`**, **`PAYLOAD_INVALID`**. |
| **`rejects future observed_at` / out-of-range glucose** | **`SEMANTIC_INVALID`** with **`field`**. |
| **`returns DUPLICATE_EVENT when dedupe enabled`** | Second identical submit with same **`DedupeTracker`**. |
| **`negative fixtures`** | **`examples/ingestion/negative-*.json`** → expected error codes. |

Additional tests: [`collectors/normalization/normalize.test.ts`](./collectors/normalization/normalize.test.ts) (timestamp / unit helpers).

---

## Docs (reference)

- **[`../RUNTIME-TEMPLATE.md`](../RUNTIME-TEMPLATE.md)** — cross-language `collectors/` + `adapters/` template.

---

## Build and test

From **`runtimes/typescript`** (or via the monorepo workspace), with the full **OpenGlucoseTelemetry** checkout so **`../../spec`** and **`../../examples`** exist:

```bash
pnpm install
pnpm build
pnpm test
```

**Smoke run** (after `pnpm build`), from this directory:

```bash
pnpm pipeline ../../examples/ingestion/healthkit-sample.json
```

**Repository root** (see repo `package.json`): **`pnpm parity:check`** exercises cross-runtime parity helpers.

---

## Relationship to Swift and other consumers

This folder is the **reference** for behavior and golden JSON. Swift **`OGTCollectorEngine.run`** follows the same stage order and error codes; it uses manual validators and an **`OGTAdapterRegistry`** (Swift) vs **`builtinIngestPlugins`** (TypeScript)—both are **table lookups**, not per-source **`if`** chains in the engine. When changing **`submit()`** behavior, update **`OGT-SWIFT-PARITY-MATRIX.md`** and Swift if you intend ports to stay aligned.
