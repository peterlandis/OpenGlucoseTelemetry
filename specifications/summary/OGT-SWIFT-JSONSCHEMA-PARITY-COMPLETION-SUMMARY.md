# OGT Swift — JSON Schema parity (pinned OGIS) — completion summary

This document summarizes the completion of work on branch **`feat/swift-jsonschema-parity`**: bundling the pinned OGIS schema into the Swift runtime and adding a lightweight JSON Schema validator (Draft 2020-12 subset) to improve long-term parity with TypeScript/Ajv.

## Deliverables

| Deliverable | Location |
|-------------|----------|
| Pinned OGIS `glucose.reading` v0.1 JSON Schema shipped with Swift runtime | `runtimes/swift/Sources/OpenGlucoseTelemetryRuntime/spec/pinned/glucose.reading.v0_1.json` |
| Swift Package resources config | `runtimes/swift/Package.swift` (`resources: [.process("spec")]`) |
| JSON Schema validator (Draft 2020-12 subset) | `runtimes/swift/Sources/OpenGlucoseTelemetryRuntime/collectors/validation/jsonschema/OGTJSONSchemaValidator.swift` |
| Schema loader (`Bundle.module`) | `runtimes/swift/Sources/OpenGlucoseTelemetryRuntime/collectors/validation/jsonschema/OGTGlucoseReadingJSONSchemaResource.swift` |
| Thin validator wrapper for pinned schema | `runtimes/swift/Sources/OpenGlucoseTelemetryRuntime/collectors/validation/jsonschema/OGTGlucoseReadingJSONSchemaValidator.swift` |
| Test ensuring the pinned schema resource is packaged | `runtimes/swift/Tests/OpenGlucoseTelemetryRuntimeTests/OGTCollectorPipelineTests.swift` (`testPinnedOGISSchemaResourceLoads`) |

## Behavior (what is validated)

The Swift validator is intentionally small but covers the OGIS v0.1 schema needs:

- **Structural rules**: `required`, `additionalProperties: false`, `type`
- **Value rules**: `enum`, `const`, `minLength`, `exclusiveMinimum`
- **Schema structure**: `$ref` + `$defs`
- **Formats**: `format: "date-time"` (ISO8601/RFC3339 with and without fractional seconds)
- **Composition + arrays (future-proofing)**: `oneOf` / `anyOf` / `allOf`, `array/items`

## Why this exists

- Keeps Swift’s schema enforcement aligned with the pinned **OGIS JSON Schema**, without requiring a full third-party JSON Schema engine.
- Makes drift harder: the pinned schema is shipped with the runtime and load-tested.
- Provides a reusable validation utility for other pinned schemas if OGT expands beyond `glucose.reading`.

## Verification

From `runtimes/swift/`:

```bash
swift test
```

## Notes / follow-ups

- The existing `OGTGlucoseReadingSchemaValidator.swift` remains a manual “Ajv parity for MVP fields” checker; this work adds an additional path to validate using the pinned schema data itself.
- If the pinned schema evolves (new keywords), extend `OGTJSONSchemaValidator` to keep parity.

---

**Last updated:** 2026-03-31

