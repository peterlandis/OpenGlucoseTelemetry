# Adapters (Swift)

One folder per `source` id, mirroring TypeScript:

| Source id | Folder | TypeScript reference |
|-----------|--------|----------------------|
| `healthkit` | `healthkit/` | `runtimes/typescript/adapters/healthkit/map.ts` |
| `dexcom` | `dexcom/` | `runtimes/typescript/adapters/dexcom/map.ts` |
| `mock` | `mock/` | `runtimes/typescript/adapters/mock/map.ts` |

Each `OGT*IngestAdapter` conforms to `OGTSourceAdapter` and implements `mapPayload(_:envelope:)` → `OGTCanonicalGlucoseReadingV01`, aligned with the corresponding TS `map.ts`.
