# OGT ↔ GlucoseAITracker (Swift) — parity matrix

**Status:** Authoritative for wave 2 ([OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-PLAN.md](../plans/OGT-CROSS-RUNTIME-PARITY-AND-CONSUMER-DOCS-PLAN.md)).  
**Owner (process):** OGT maintainers update this when `runtimes/typescript/collectors/` semantic/normalize behavior or GlucoseAITracker `OGTGlucoseIngestPipeline` / `GlucoseReadingCanonicalMapper` changes.

## How to use this document

Use the table to see whether the **TypeScript reference pipeline** and the **in-app Swift subset** enforce the same rules for OGIS `glucose.reading` v0.1 ingest. **Intentional differences** are called out with a short rationale and (where applicable) a follow-up owner.

| Rule / check | TypeScript (OGT) | Swift (GlucoseAITracker) | Match? | Notes / owner |
|--------------|------------------|---------------------------|--------|----------------|
| **`event_type` = `glucose.reading`** | Set in adapters (e.g. `runtimes/typescript/adapters/healthkit/map.ts`); final output validated by Ajv against pinned schema (`runtimes/typescript/collectors/validators.ts` → `spec/pinned/glucose.reading.v0_1.json`). | `GlucoseReadingCanonical` defaults; `OGTGlucoseIngestPipeline.validate` rejects wrong `eventType`. | **Yes** | Swift does not run Ajv; same literal enforced in code + types. |
| **`event_version` = `0.1`** | Same as above (adapters + schema `const`). | Pipeline validates `eventVersion == "0.1"`. | **Yes** | |
| **Ingestion envelope** (`source`, `trace_id`, `adapter`, payload schemas) | `validateEnvelope` + per-source payload schemas in `submit()` (`runtimes/typescript/collectors/pipeline.ts`). | *N/A* — app maps **`Glucose` → canonical** directly; no wire envelope on device. | **N/A** | Parity is **canonical + semantic** layer, not envelope parsing. |
| **Non-empty `subject_id`** | OGIS schema `minLength: 1` on `subject_id` (`spec/pinned/glucose.reading.v0_1.json`). | `OGTGlucoseIngestPipeline`: `.emptySubjectId` if `subjectId.isEmpty`. | **Yes** | |
| **Non-empty `provenance.raw_event_id`** | After `normalizeCanonicalReading`, trimmed string; empty fails schema (`minLength: 1`). | Explicit `.emptyRawEventId` if `rawEventId.isEmpty` (mapper uses `glucose.id.uuidString`). | **Yes** | TS: whitespace-only collapses to empty on trim → schema failure. |
| **Non-empty `provenance.source_system`** | Schema `minLength: 1`; normalize trims (`runtimes/typescript/collectors/normalize.ts`). | Explicit `.emptySourceSystem`. | **Yes** | |
| **Non-empty `provenance.adapter_version`** | Schema `minLength: 1`; normalize trims. | Explicit `.emptyAdapterVersion`. | **Yes** | |
| **Whitespace-only provenance / optional device strings** | `boundOptionalString` trims; empty → omit optional `device.manufacturer` / `model`; required provenance fields trimmed but not dropped (empty → schema error). | Device strings pass through from `Glucose` (`GlucoseReadingCanonicalMapper`); no TS-style trim/omit for manufacturer/model. | **Partial** | Rare edge case: TS may omit empty optional device fields; Swift may keep `nil` or vendor strings as mapped. **Owner:** align only if wire export requires identical optional-key presence. |
| **`value` > 0 (schema)** | OGIS `exclusiveMinimum: 0` enforced by Ajv after semantic pass. | `value <= 0` → `.valueOutOfClinicalRangemgDl`. | **Yes** | Swift folds non-positive into clinical failure path; effect is reject. |
| **Clinical range 20–600 mg/dL equivalent** | After normalization to mg/dL, `applySemanticRules` (`runtimes/typescript/collectors/semantic.ts`) enforces `MGDL_MIN` / `MGDL_MAX`. | Same numeric bounds on mg/dL equivalent (`OGTGlucoseIngestPipeline`: `minMgDl` / `maxMgDl`). | **Yes** | Apply **after** unit normalization in both paths. |
| **mmol/L → mg/dL factor** | `MGDL_PER_MMOL = 18.018` (`runtimes/typescript/collectors/normalize.ts`); OGIS [unit-semantics](https://github.com/peterlandis/OpenGlucoseInteroperabilityStandard/blob/main/spec/core/unit-semantics.md). | `* 18.0` / `/ 18.0` in `OGTGlucoseIngestPipeline` and `GlucoseReadingCanonicalMapper`. | **No** | **Intentional drift (pending app fix):** Swift uses **18.0**; TS uses **18.018**. Same rationale must be documented in GlucoseAITracker when updated. **Owner:** GlucoseAITracker — align constants to **18.018** (see matrix row in completion summary). |
| **Rounding mg/dL (converted values)** | `roundMgdl` to one decimal (`runtimes/typescript/collectors/normalize.ts`). | No equivalent rounding in pipeline validator; mapper returns native `Double`. | **Partial** | Small numeric differences vs TS for mmol/L inputs. **Owner:** optional Swift alignment if export must match TS rounding. |
| **Future `observed_at` (clock skew)** | Rejects if `observed_at > now + FUTURE_SKEW_MS` (15 minutes) (`runtimes/typescript/collectors/semantic.ts`). | No `Date()` comparison in `OGTGlucoseIngestPipeline`. | **No** | **Waived (Swift):** On-device subset omits future-skew policy to avoid surprising drops when device clock or backfill semantics differ; **documented** for implementers. Revisit if product requires parity. **Owner:** GlucoseAITracker product + OGT matrix. |
| **Future `source_recorded_at`** | Same 15-minute skew rule when field present (`semantic.ts`). | No check. | **No** | Same **Waived** rationale as `observed_at`. |
| **`observed_at` / timestamps parseable** | `normalizeTimestamp` throws → `MAPPING_FAILED`; semantic layer also parses for skew/range. | `Date` values from `Glucose` (no string parse in pipeline). | **N/A** | Swift path assumes valid `Date`; TS path parses RFC 3339 strings. |
| **Normalize `received_at`** | Set from envelope if missing, normalized ISO (`normalizeCanonicalReading`). | Mapper sets `receivedAt: nil` unless populated elsewhere. | **Partial** | Different ingress shape; compare **exported** JSON if testing parity. |
| **Full OGIS JSON Schema (Ajv)** | Final `validateGlucoseReadingOgis` in `submit()`. | **Subset** validation in Swift only (see GAT completion summary). | **Partial** | Swift intentionally does not embed Ajv; parity is **documented rules**, not byte-identical schema execution. |
| **Dedupe** | Optional `DedupeTracker` in `submit()` options (`runtimes/typescript/collectors/pipeline.ts`). | `filterPersistableReadings` filters per reading; no shared dedupe key store in pipeline. | **Partial** | Same **key concept** possible; TS-only helper today. |

## References

- **OGT:** `runtimes/typescript/collectors/semantic.ts`, `runtimes/typescript/collectors/normalize.ts`, `runtimes/typescript/collectors/pipeline.ts`, `runtimes/typescript/collectors/validators.ts`
- **Swift:** `OGTGlucoseIngestPipeline.swift`, `GlucoseReadingCanonicalMapper.swift`, `GlucoseReadingCanonical.swift`
- **OGIS:** [unit-semantics](../../../OpenGlucoseInteroperabilityStandard/spec/core/unit-semantics.md) (conversion **18.018** conformance), [time-semantics](../../../OpenGlucoseInteroperabilityStandard/spec/core/time-semantics.md) (RFC 3339 wire notes), [source_system registry](../../../OpenGlucoseInteroperabilityStandard/spec/core/source-system-registry.md) — sibling [OpenGlucoseInteroperabilityStandard](https://github.com/peterlandis/OpenGlucoseInteroperabilityStandard) checkout under the same workspace parent
- **Consumer pattern:** [OGT-OGIS-INTEGRATION.md](../../../GlucoseAITracker/Documentation/OGT-OGIS-INTEGRATION.md) (sibling checkout under the same workspace parent as this repo)

---

**Last updated:** 2026-03-30
