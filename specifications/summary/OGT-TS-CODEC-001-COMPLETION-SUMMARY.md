# OGT-TS-CODEC-001 — Timestamp codec completion summary

This document summarizes the completion of **OGT-TS-CODEC-001**: establishing a single, parity-aligned RFC3339/ISO8601 timestamp codec surface in the **OpenGlucoseTelemetry Swift runtime**, matching the intent of the TypeScript runtime’s `normalizeTimestamp`.

## Deliverable

- **New centralized codec:** `OGTRFC3339`  
  Location: `runtimes/swift/Sources/OpenGlucoseTelemetryRuntime/collectors/normalization/OGTRFC3339.swift`
- **Single normalization entrypoint used by normalization + validation:** timestamp parsing/epoch-ms extraction/normalization is routed through `OGTRFC3339` (no ad hoc parsing at call sites).

## Behavior (policy)

Parity policy implemented (per file docstring):

- Accept RFC3339 / ISO8601 timestamps **with or without fractional seconds**
- Interpret and emit timestamps in **UTC**
- Normalize to **milliseconds precision** (sub-millisecond precision is dropped)

## What changed

- Added `OGTRFC3339` with:
  - `decode(_:) -> Date?`
  - `epochMs(_:) -> Int64?`
  - `normalizeToMillisUTC(_:) throws -> String`
  - `encodeMillisUTC(_:) -> String`
- Updated normalization to use the codec as the single boundary:
  - `ogtNormalizeTimestamp(iso:)` now delegates to `OGTRFC3339.normalizeToMillisUTC(_:)`
  - `ogtIsValidOgDateTimeString(_:)` uses `OGTRFC3339.decode(_:)`
- Updated schema and semantic validation timestamp parsing to use `OGTRFC3339.epochMs(_:)`:
  - `OGTGlucoseReadingSchemaValidator` (date-time format checks)
  - `OGTSemanticValidator` (future-skew checks)

## Verification

From `runtimes/swift/`:

```bash
swift build
swift test
```

## Notes / follow-ups

- This feature intentionally centralizes timestamp handling in one codec to prevent drift between:
  - normalization (canonical formatting)
  - schema validation (`format: date-time`)
  - semantic validation (epoch-ms comparisons)
- Any future runtime changes that touch timestamp semantics should update `OGTRFC3339` first and keep downstream call sites delegating to it.

