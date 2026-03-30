# HealthKit adapter (fixture JSON)

Maps a **serializable** HealthKit-shaped `payload` (see `spec/healthkit-payload.schema.json`) to OGIS `glucose.reading` v0.1. GlucoseAITracker should build the same JSON from `HKQuantitySample` when the OGT pipeline is enabled.

## Field mapping

| HK JSON field | OGIS / canonical field | Notes |
|---------------|------------------------|--------|
| `subject_id` | `subject_id` | Producer namespace id (required on payload). |
| `startDate` | `observed_at` | Clinical observation time; normalized to UTC ISO. |
| `endDate` | `source_recorded_at` | Set only when `endDate` ≠ `startDate`. |
| `value` | `value` | Pre-normalization; pipeline converts to `mg/dL` per GAT policy. |
| `unit` | `unit` | `mg/dL` or `mmol/L`; normalized to `mg/dL`. |
| `uuid` | `provenance.raw_event_id` | Stable HK sample identifier. |
| — | `provenance.source_system` | Constant `com.apple.health`. |
| Envelope `adapter.version` | `provenance.adapter_version` | From ingestion envelope. |
| Envelope `received_at` | `provenance.ingested_at`, `received_at` | Ingest boundary; normalized. |
| `sourceName` | `device.manufacturer` | Best-effort display name. |
| `sourceBundleId` | `device.model` | Bundle id stored as model hint for MVP. |
| `metadata.HKWasUserEntered` | `measurement_source` | `true` → `manual`. |
| `sourceBundleId` heuristics | `measurement_source` | Dexcom / Libre / Freestyle / Medtronic substring → `cgm`; else `bgm`. |
| Inferred class | `device.type` | Aligns with `measurement_source` (`cgm` / `bgm` / `app` for manual). |

## Building payload from `HKQuantitySample` (GlucoseAITracker)

1. `uuid`: `sample.uuid.uuidString`
2. `value`: quantity in `mg/dL` or `mmol/L` (match `unit` string to OGIS enums exactly).
3. `startDate` / `endDate`: `ISO8601DateFormatter` with UTC `Z` (or offset) per OGIS time semantics.
4. `sourceName` / `sourceBundleId`: from `sample.sourceRevision.source`
5. `metadata`: export relevant `HKMetadata` keys as string/boolean values (e.g. `HKWasUserEntered`).

Behavioral parity: run the same fixture through this repo’s `pnpm test` golden path and compare to the in-app pipeline output when the feature flag is on.
