# Swift runtime — package completion summary

This document summarizes how the **OpenGlucoseTelemetry** Swift runtime is delivered and what was established for **Swift Package Manager** consumption.

## Deliverable

- **Package name:** `OpenGlucoseTelemetryRuntime` (SwiftPM library product).
- **Manifest:** `runtimes/swift/Package.swift` (`swift-tools-version: 5.10`).
- **Minimum platforms:** iOS 17, macOS 14, watchOS 10.
- **Library target:** `runtimes/swift/Sources/OpenGlucoseTelemetryRuntime/` — collectors (orchestration) and adapters (per-source mapping), mirroring the TypeScript layout under `runtimes/typescript`.
- **Tests:** `runtimes/swift/Tests/OpenGlucoseTelemetryRuntimeTests/` — pipeline, repository-root, and adapter/collector example tests.
- **Optional executable:** `RunPipelineExample` — CLI to decode an ingestion envelope and print canonical JSON or a structured error (`runtimes/swift/examples/RunPipelineExample`).

## Public API (app-facing)

Types intended for consumers (e.g. **GlucoseAITracker**) include:

- **Pipeline:** `OGTCollectorPipeline`, `OGTReferenceCollector`, `OGTCollectorEngine`
- **Wire / options / results:** `OGTIngestionEnvelope`, `OGTSubmitOptions`, `OGTPipelineResult`, `OGTStructuredPipelineError`, `OGTPipelineIssueCode`
- **Adapters / registry:** `OGTSourceAdapter`, `OGTAdapterRegistration`, `OGTAdapterRegistry`, `OGTDefaultAdapterRegistry`, `OGTAdapterCatalog`
- **Canonical model:** `OGTCanonicalGlucoseReadingV1` and related nested types

Supporting types (`OGTJSONValue`, validators, normalizers, etc.) are public where needed for extension or testing. The package does **not** depend on any application target, Core Data, or **GlucoseAITracker**.

## Schemas and fixtures

JSON schemas and sample envelopes live at the **OpenGlucoseTelemetry** repo root (`spec/`, `examples/`). The library does not bundle them as resources; tests and `RunPipelineExample` resolve files via **`OGTRepositoryRoot`** when run from a full checkout.

## Verification

From `runtimes/swift/`:

```bash
swift build
swift test
```

## Documentation for app integration

Step-by-step instructions for adding this package to an Xcode app (including **GlucoseAITracker**) are in **[`runtimes/swift/README.md`](../../runtimes/swift/README.md)** under **Integrating into an app (e.g. GlucoseAITracker)**.

## Related docs

- [`runtimes/swift/README.md`](../../runtimes/swift/README.md) — overview, architecture, build/test, integration
- [`runtimes/swift/ARCHITECTURE.md`](../../runtimes/swift/ARCHITECTURE.md) — folder layout
- [`runtimes/RUNTIME-TEMPLATE.md`](../../runtimes/RUNTIME-TEMPLATE.md) — cross-runtime template
- [`specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md`](../handoff/OGT-SWIFT-PARITY-MATRIX.md) — TS/Swift parity
