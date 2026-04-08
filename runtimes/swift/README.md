# Open Glucose Telemetry — Swift runtime

Swift Package Manager library **OpenGlucoseTelemetryRuntime**, structured like the TypeScript reference under [`../typescript`](../typescript): shared **`collectors/`** (orchestration) and **`adapters/`** (per-source mapping).

Shared contracts (schemas, fixtures) live at the repo root: [`../../spec`](../../spec), [`../../examples`](../../examples). Parity expectations: [`../../specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md`](../../specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md).

---

## Architecture (this package)

**Collectors** implement the full **ingestion pipeline** (parity with TypeScript **`pipeline.ts`** `submit`): validate envelope and per-source payload → **`OGTAdapterRegistry.mapPayload`** → normalize → semantic rules → optional dedupe → OGIS-shaped checks. The public entry is **`OGTReferenceCollector`**, which implements **`OGTCollectorPipeline`** and delegates to **`OGTCollectorEngine.run`**.

**Adapters** live under **`adapters/<source>/`** (`healthkit`, `dexcom`, `mock`). Each implements **`OGTSourceAdapter`** — **`mapPayload`** turns the envelope’s **`payload`** into **`OGTCanonicalGlucoseReadingV1`** before normalization. **`OGTDefaultAdapterRegistry`** dispatches the MVP sources.

```text
JSON (ingestion envelope)
  → OGTIngestionEnvelope.decode(from:)
  → OGTCollectorPipeline.submit(envelope:options:)
  → validate envelope + payload
  → OGTAdapterRegistry.mapPayload(for:payload:envelope:)
  → ogtNormalizeCanonicalReading, ogtApplySemanticRules, optional dedupe
  → ogtValidateGlucoseReadingOgis
  → OGTPipelineResult (.success(reading) | .failure(structured))
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
| **`testExample_injectCollectorPipelineProtocol`** | Depends on **`OGTCollectorPipeline`** with **`OGTReferenceCollector`** and the default registry (real **`mock`** adapter). |

Additional regression tests: [`OGTCollectorPipelineTests.swift`](./Tests/OpenGlucoseTelemetryRuntimeTests/OGTCollectorPipelineTests.swift), [`OGTRepositoryRootTests.swift`](./Tests/OpenGlucoseTelemetryRuntimeTests/OGTRepositoryRootTests.swift).

---

## Docs (reference)

- **[`../RUNTIME-TEMPLATE.md`](../RUNTIME-TEMPLATE.md)** — cross-language `collectors/` + `adapters/` template.
- **[`specifications/summary/OGT-SWIFT-PACKAGE-COMPLETION-SUMMARY.md`](../../specifications/summary/OGT-SWIFT-PACKAGE-COMPLETION-SUMMARY.md)** — SPM layout, public API checklist, and verification notes.

---

## Build and test

From this directory, with the full **OpenGlucoseTelemetry** repo checked out (so `../../spec` exists and example tests can read `examples/`):

```bash
swift build
swift test
```

**Runnable example** (collector + default adapters on a sample envelope): see **[`examples/README.md`](./examples/README.md)** — `swift run RunPipelineExample` (optional path to envelope JSON).

For step-by-step app integration (including **GlucoseAITracker**), see **[Integrating into an app](#integrating-into-an-app-e-g-glucoseaitracker)** below.

---

## Integrating into an app (e.g. GlucoseAITracker)

The library is a normal **Swift Package** product: **`OpenGlucoseTelemetryRuntime`**. This section describes adding it to an **Xcode** app that lives alongside or separately from this repo.

### 1. Add the package in Xcode

**Option A — local path (monorepo / same machine)**  

1. Open your app project (e.g. `GlucoseAITracker.xcodeproj`).  
2. **File → Add Package Dependencies…**  
3. Click **Add Local…** and select this directory (the folder that contains **`Package.swift`**):

   `OpenGlucoseTelemetry/runtimes/swift`

   From a sibling checkout, the relative path is often `../OpenGlucoseTelemetry/runtimes/swift`.

**Option B — Git remote**  

1. **File → Add Package Dependencies…** → enter the **OpenGlucoseTelemetry** repository URL.  
2. Choose a **branch** or **version** rule.  
3. Because **`Package.swift`** is not at the repository root, set the **package / subpath** (wording varies by Xcode version) to:

   `runtimes/swift`

   If Xcode does not offer a subpath field, clone locally and use **Option A**, or add a root `Package.swift` in the repo that wraps this package (not provided here).

### 2. Link the product to targets

In the package dependency sheet, add **`OpenGlucoseTelemetryRuntime`** to every target that should compile against it, for example:

- **iOS app** target  
- **watchOS app** target (if the watch extension runs the same ingestion pipeline)

Confirm under the target’s **General** tab (or **Frameworks, Libraries, and Embedded Content**) that **`OpenGlucoseTelemetryRuntime`** appears for that target.

### 3. Import and call the pipeline

```swift
import OpenGlucoseTelemetryRuntime

// Decode wire JSON or build OGTIngestionEnvelope in memory.
let envelope: OGTIngestionEnvelope = try OGTIngestionEnvelope.decode(from: jsonData)

let pipeline: OGTReferenceCollector = OGTReferenceCollector()
let result: OGTPipelineResult = pipeline.submit(envelope: envelope)

switch result {
case .success(let reading):
    // OGTCanonicalGlucoseReadingV1 — map into your app / Core Data models.
    _ = reading
case .failure(let error):
    // OGTStructuredPipelineError (code, traceId, message, optional field)
    _ = error
}
```

**Alternatives:** call **`OGTCollectorEngine.run(envelope:options:)`** directly, or pass **`OGTSubmitOptions`** for a custom **`OGTAdapterRegistry`** or **`OGTDedupeTracker`**. See **[Example tests](#example-tests-walking-through-usage)** and **`collectors/README.md`**.

**Bulk insight / chart gating:** When re-running normalization + **`ogtApplySemanticRules`** + **`ogtValidateGlucoseReadingOgis`** over many persisted readings, build timestamps with **`OGTRFC3339.encodeMillisUTC`** and use **`ogtNormalizeCanonicalReadingTrustedMillisEncodedRFC3339`** instead of **`ogtNormalizeCanonicalReading`** so timestamp strings are not re-parsed through ICU on every row. Details and caveats: **[`collectors/README.md` — Performance: bulk re-validation](Sources/OpenGlucoseTelemetryRuntime/collectors/README.md#performance-bulk-re-validation-eg-insight-gating)**.

### 4. Platform requirements

This package declares **iOS 17**, **macOS 14**, and **watchOS 10** minimums in **`Package.swift`**. App targets must meet those deployment targets (or you must lower the package’s platform versions in a fork).

### 5. How this relates to app-specific code

The package does **not** import your app. Your app is responsible for:

1. Building **`OGTIngestionEnvelope`** (e.g. from HealthKit samples, Dexcom exports, or tests) in the JSON shape defined by **`spec/ingestion-envelope.schema.json`**.  
2. Running **`OGTReferenceCollector`** (or **`OGTCollectorEngine`**) and handling **`OGTPipelineResult`**.  
3. Mapping **`OGTCanonicalGlucoseReadingV1`** into your domain models (e.g. existing in-app **`OGTGlucoseIngestPipeline`**-style helpers can wrap or converge with this over time).

---

## Relationship to GlucoseAITracker

**GlucoseAITracker** can depend on **`OpenGlucoseTelemetryRuntime`** as above: serialize sources into an **`OGTIngestionEnvelope`**, call **`OGTReferenceCollector().submit(envelope:)`**, and branch on **`OGTPipelineResult`**. In-app pipeline types can gradually align with or delegate to the shared runtime.
