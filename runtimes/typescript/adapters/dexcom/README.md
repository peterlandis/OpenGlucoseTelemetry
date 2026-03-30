# Dexcom adapter (fixture JSON)

Maps a **serializable** Dexcom-shaped `payload` (see `spec/dexcom-payload.schema.json`) to OGIS `glucose.reading` v0.1. Intended for:

- **Fixture tests** and CI (no credentials).
- **App integration:** build the same JSON from Dexcom API responses (e.g. EGV / estimated glucose value records) or cached rows, then wrap it in an ingestion envelope with `source: "dexcom"`.

Live HTTP to Dexcom cloud is **not** in this adapter; that remains a separate “cloud adapter” concern (polling, OAuth, rate limits).

## Ingestion envelope

Use `source: "dexcom"` and `adapter.id` such as `ogt.adapter.dexcom`.

## Field mapping

| Payload field | OGIS / canonical field | Notes |
|---------------|------------------------|--------|
| `subject_id` | `subject_id` | Producer namespace id. |
| `system_time` | `observed_at` | Dexcom **systemTime** (UTC); normalized in pipeline. |
| `display_time` | `source_recorded_at` | Set only when present **and** not equal to `system_time` (string compare after trim). |
| `value`, `unit` | `value`, `unit` | Normalized to **mg/dL** in the collector. |
| `event_id` | `provenance.raw_event_id` | Stable id (transaction id, UUID, etc.). |
| — | `provenance.source_system` | Constant `dexcom`. |
| Envelope `adapter.version` | `provenance.adapter_version` | |
| Envelope `received_at` | `provenance.ingested_at`, `received_at` | |
| — | `measurement_source` | Always `cgm`. |
| — | `device.manufacturer` | Always `Dexcom`. |
| `device_model` | `device.model` | e.g. G6, G7. |
| — | `device.type` | `cgm`. |
| `trend_arrow` | `trend.direction` | Dexcom tokens mapped (e.g. `flat`/`none` → `stable`, `singleUp` → `rising`). |
| `trend_rate` | `trend.rate` | Optional. |
| `trend_rate_unit` | `trend.rate_unit` | Optional; use units consistent with `unit` when possible. |
| `quality_status` | `quality.status` | Optional OGIS enum. |

### Dexcom `trend` / `trendArrow` tokens

Common API values include: `none`, `doubleUp`, `singleUp`, `fortyFiveUp`, `flat`, `fortyFiveDown`, `singleDown`, `doubleDown`, `notComputable`. Map them into payload `trend_arrow` as strings; the adapter normalizes case and maps to OGIS `rising` | `falling` | `stable` | `unknown`.
