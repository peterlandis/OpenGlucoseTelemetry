# Adapters (MVP)

Source-specific mappers from ingestion `payload` to pre-normalization canonical `glucose.reading` fields.

| Source id   | Module            | Notes                          |
|------------|-------------------|--------------------------------|
| `healthkit` | `healthkit/map.ts` | Serializable HK sample JSON    |
| `mock`      | `mock/map.ts`      | Integration tests / smoke runs |
