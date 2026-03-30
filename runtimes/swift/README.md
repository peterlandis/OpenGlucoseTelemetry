# Open Glucose Telemetry — Swift runtime

Swift Package Manager library **OpenGlucoseTelemetryRuntime**, structured like the TypeScript reference under [`../typescript`](../typescript): shared **`collectors/`** (orchestration) and **`adapters/`** (per-source mapping).

Shared contracts (schemas, fixtures) live at the repo root: [`../../spec`](../../spec), [`../../examples`](../../examples). Parity expectations: [`../../specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md`](../../specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md).

---

## Architecture (this package)

**Collectors** implement the full **ingestion pipeline** (parity with TypeScript **`pipeline.ts`** `submit`): validate envelope and per-source payload → **`OGTAdapterRegistry.mapPayload`** → normalize → semantic rules → optional dedupe → OGIS-shaped checks. The public entry is **`OGTReferenceCollectorPipeline`**, which implements **`OGTCollectorPipeline`** and delegates to **`OGTCollectorSubmit.run`**.

**Adapters** live under **`adapters/<source>/`** (`healthkit`, `dexcom`, `mock`). Each implements **`OGTSourceAdapter`** — **`mapPayload`** turns the envelope’s **`payload`** into **`OGTCanonicalGlucoseReadingV01`** before normalization. **`OGTDefaultAdapterRegistry`** dispatches the MVP sources.

```text
JSON (ingestion envelope)
  → OGTIngestionEnvelope.decode(from:)
  → OGTCollectorPipeline.submit(envelope:options:)
  → validate envelope + payload
  → OGTAdapterRegistry.mapPayload(for:payload:envelope:)
  → ogtNormalizeCanonicalReading, ogtApplySemanticRules, optional dedupe
  → ogtValidateGlucoseReadingOgis
  → OGTPipelineSubmitResult (.success(reading) | .failure(structured))
```

**Optional:** pass **`OGTSubmitOptions(adapterRegistry:)`** to inject a test or custom registry; **`dedupeTracker`** enables in-memory dedupe like the TS runtime.

**Not the ingest path:** **`OGTRepositoryRoot`** only finds the repo root for tests/tools (see [`collectors/README.md`](./Sources/OpenGlucoseTelemetryRuntime/collectors/README.md)).

More detail: **[`collectors/README.md`](./Sources/OpenGlucoseTelemetryRuntime/collectors/README.md)** (diagram, which pipeline type to use, file table), **[`ARCHITECTURE.md`](./ARCHITECTURE.md)** (folder layout).

---

## Example tests: walking through usage

The **[`Tests/OpenGlucoseTelemetryRuntimeTests/OGTCollectorAndAdapterExampleTests.swift`](./Tests/OpenGlucoseTelemetryRuntimeTests/OGTCollectorAndAdapterExampleTests.swift)** file is the **guided walkthrough** for collectors + adapters.

| Test | What it shows |
|------|----------------|
| **`testExample_stubRegistry_collectorReturnsSuccess`** | Mock envelope JSON → **`submit(..., options: OGTSubmitOptions(adapterRegistry: ExampleStubRegistry()))`** → **`.success`** with a canonical reading (stub bypasses **`OGTMockIngestAdapter`** mapping). |
| **`testExample_defaultRegistry_dispatchesToHealthKitAdapter`** | Repo **`examples/ingestion/healthkit-sample.json`** → default registry → real **`OGTHealthKitIngestAdapter`** → **`.success`**. |
| **`testExample_injectCollectorPipelineProtocol`** | Depends on **`OGTCollectorPipeline`** with **`OGTReferenceCollectorPipeline`** and the default registry (real **`mock`** adapter). |

Additional regression tests: [`OGTCollectorPipelineTests.swift`](./Tests/OpenGlucoseTelemetryRuntimeTests/OGTCollectorPipelineTests.swift), [`OGTRepositoryRootTests.swift`](./Tests/OpenGlucoseTelemetryRuntimeTests/OGTRepositoryRootTests.swift).

---

## Docs (reference)

- **[`../RUNTIME-TEMPLATE.md`](../RUNTIME-TEMPLATE.md)** — cross-language `collectors/` + `adapters/` template.

---

## Build and test

From this directory, with the full **OpenGlucoseTelemetry** repo checked out (so `../../spec` exists and example tests can read `examples/`):

```bash
swift build
swift test
```

**Runnable example** (collector + default adapters on a sample envelope): see **[`examples/README.md`](./examples/README.md)** — `swift run RunPipelineExample` (optional path to envelope JSON).

Add a **local package** dependency pointing at `runtimes/swift` from an app or framework.

---

## Relationship to GlucoseAITracker

Add **`OpenGlucoseTelemetryRuntime`** as a dependency, serialize HealthKit (or other) reads into an **`OGTIngestionEnvelope`**, then call **`OGTReferenceCollectorPipeline().submit(envelope:)`** and switch on **`OGTPipelineSubmitResult`**. Shared logic can replace or wrap in-app pipeline types (`OGTGlucoseIngestPipeline`, etc.) over time.
