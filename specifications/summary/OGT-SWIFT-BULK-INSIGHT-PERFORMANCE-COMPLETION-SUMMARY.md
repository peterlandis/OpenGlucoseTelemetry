# OpenGlucoseTelemetry — Swift runtime bulk re-validation & RFC3339 performance — Completion summary

**Repository:** OpenGlucoseTelemetry  
**Package:** `runtimes/swift` → **OpenGlucoseTelemetryRuntime**  
**Scope:** Performance and embedder ergonomics for **large-scale** re-validation of canonical glucose readings (e.g. insight/chart gating) without changing the default **ingestion envelope** pipeline.  
**Cross-reference (app integration + Core Data/UI):** GlucoseAITracker `specifications/summary/GLUCOSE-PERF-LAUNCH-INSIGHTS-COMPLETION-SUMMARY.md`  
**Technical docs in-tree:** `runtimes/swift/Sources/OpenGlucoseTelemetryRuntime/collectors/README.md` (section **Performance: bulk re-validation**), `runtimes/swift/README.md` (integration note)  
**Last updated:** 2026-04-08

---

## Executive summary

Embedders that map persisted **Date-native** canonical data into **`OGTCanonicalGlucoseReadingV1`** using **`OGTRFC3339.encodeMillisUTC(_:)`** and then call **`ogtNormalizeCanonicalReading`** were forcing **redundant work**: every timestamp string was **parsed again** through **`ISO8601DateFormatter`** (ICU). Downstream, **`ogtApplySemanticRules`** and **`ogtValidateGlucoseReadingOgis`** call **`OGTRFC3339.epochMs`**, which previously always went through the same expensive **`decode`** path for each field, **per row**, at scale (tens of thousands of readings).

This completion slice delivers:

1. **`ogtNormalizeCanonicalReadingTrustedMillisEncodedRFC3339`** — public API; same **mg/dL** normalization, **string bounds**, and **received_at** envelope fallback semantics as **`ogtNormalizeCanonicalReading`** for the trusted case, but **no** **`ogtNormalizeTimestamp`** / ICU parse on timestamp fields.
2. **`OGTRFC3339.decode` / `epochMs` optimization** — for strict UTC **Zulu** shapes **`YYYY-MM-DDTHH:MM:SS.sssZ`** (24 ASCII characters) and **`YYYY-MM-DDTHH:MM:SSZ`** (20 characters), parse with **ASCII digit extraction + UTC `Calendar`** before falling back to **`ISO8601DateFormatter`**.

The **default collector path** (**`OGTCollectorEngine.run`**) is **unchanged**: it still uses **`ogtNormalizeCanonicalReading`** for arbitrary adapter output.

---

## Problem statement

| Issue | Detail |
|--------|--------|
| **Double encode→parse** | Bulk paths built wire timestamps with **`encodeMillisUTC`**, then **`ogtNormalizeCanonicalReading`** called **`normalizeToMillisUTC`** / **`decode`** on the same logical instants. |
| **Validators multiplied cost** | **`ogtApplySemanticRules`** uses **`epochMs(observedAt)`** and optional **`epochMs(sourceRecordedAt)`**. **`ogtValidateGlucoseReadingOgis`** uses **`epochMs`** on up to four timestamp strings. Per row, that was **many ICU parses** even after normalization. |
| **Instruments signature** | Time Profiler / Hangs often showed **`icu::SimpleDateFormat`**, **`CFDateFormatter`**, **`libicucore`** under OGT symbol names when embedders filtered large canonical arrays on device. |

---

## Solution design

### Trusted canonical normalization

- **When to use:** Call **`ogtNormalizeCanonicalReadingTrustedMillisEncodedRFC3339(reading:envelopeReceivedAt:)`** only when **`reading.observedAt`**, optional **`sourceRecordedAt` / `receivedAt`**, **`provenance.ingestedAt`**, and **`envelopeReceivedAt`** are already in the **same normalized form** as **`OGTRFC3339.encodeMillisUTC(_:)`** (UTC, millisecond precision in the wire string).
- **When not to use:** Vendor JSON, Dexcom/HealthKit adapter output, or any string that has **not** been produced by **`encodeMillisUTC`** (or equivalent) must continue through **`ogtNormalizeCanonicalReading`** so **ISO8601** parsing normalizes variant wire shapes.

### RFC3339 ASCII fast path

- **Shapes handled:** Fixed-layout Zulu UTC strings as above; matches typical **`encodeMillisUTC`** output length and punctuation.
- **Fallback:** Any other RFC3339 / ISO8601 variant still uses existing **`fractional`** / **`plain`** **`ISO8601DateFormatter`** chain (parity with previous behavior).

### TypeScript runtime

- No change to **`runtimes/typescript`** in this slice: the trusted path is an **embedder-side optimization** for Swift **Date → string → already-normalized** workflows. Cross-runtime behavioral parity for **ingestion** remains defined by the existing TS collector; Swift bulk re-validation is documented as a **supported consumption pattern**, not a second truth pipeline.

---

## Public API

| Symbol | Change |
|--------|--------|
| **`ogtNormalizeCanonicalReadingTrustedMillisEncodedRFC3339(reading:envelopeReceivedAt:)`** | **New** public function in **`OGTNormalizer.swift`**. |
| **`OGTRFC3339.decode(_:)`** | Same signature; **faster** for matching Zulu ASCII shapes. |
| **`OGTRFC3339.epochMs(_:)`** | Same signature; benefits via **`decode`**. |
| **`ogtNormalizeCanonicalReading`** | Unchanged; still used by **`OGTCollectorEngine`**. |

---

## Files touched

| Path (from repo root) | Role |
|------------------------|------|
| `runtimes/swift/Sources/OpenGlucoseTelemetryRuntime/collectors/normalization/OGTNormalizer.swift` | Trusted normalizer implementation + documentation. |
| `runtimes/swift/Sources/OpenGlucoseTelemetryRuntime/collectors/normalization/OGTRFC3339.swift` | UTC calendar + ASCII parsers + **`decode`** ordering. |
| `runtimes/swift/Tests/OpenGlucoseTelemetryRuntimeTests/OGTCollectorPipelineTests.swift` | New regression tests (see below). |
| `runtimes/swift/Sources/OpenGlucoseTelemetryRuntime/collectors/README.md` | Pipeline step 5 note, **`normalization/`** table, **Performance: bulk re-validation** section. |
| `runtimes/swift/README.md` | **Integrating into an app** — bulk insight gating paragraph + link. |
| `specifications/summary/OGT-SWIFT-BULK-INSIGHT-PERFORMANCE-COMPLETION-SUMMARY.md` | This document. |

---

## Tests added

| Test | Assertion |
|------|-----------|
| **`testTrustedMillisNormalizationMatchesFullPathWhenEncodedFromDate`** | **`ogtNormalizeCanonicalReadingTrustedMillisEncodedRFC3339`** output equals **`ogtNormalizeCanonicalReading`** when inputs are built from **`encodeMillisUTC`** (includes **mmol/L → mg/dL** path). |
| **`testDecodeFastPathMatchesEncodeMillisUTC`** | **`decode`** and **`epochMs`** agree with ms-rounded **`Date`** for several **`encodeMillisUTC`** samples. |

Existing pipeline and fixture tests continue to validate unchanged ingest behavior.

---

## Verification

From a full **OpenGlucoseTelemetry** checkout (so **`examples/`** and repo-root **`spec/`** resolve for tests):

```bash
cd runtimes/swift
swift build
swift test
```

Embedders should **clean-build** after updating the package revision and re-run **Instruments** on their bulk re-validation path to confirm ICU samples drop.

---

## Success criteria

- **Correctness:** Trusted normalizer matches full normalizer for **`encodeMillisUTC`**-sourced timestamp strings (test-locked).
- **Performance:** **`decode` / `epochMs`** avoid ICU on the fixed Zulu shapes used after **`encodeMillisUTC`**.
- **Safety:** Default **ingest** pipeline behavior and public contracts for arbitrary wire timestamps are **unchanged**.
- **Documentation:** Embedders can discover the pattern from **`collectors/README.md`** and **`runtimes/swift/README.md`**.

---

## Follow-ups (optional)

- Consider a **single-pass** semantic + schema API that accepts **epoch milliseconds** for trusted rows to avoid repeated string work entirely (larger API surface; would need careful OGIS parity review).
- If **TypeScript** embedders need the same pattern, add a documented parallel or shared test vectors in **`specifications/handoff`**.

---

## Git / release

Implementation and in-package docs landed on branch **`perf/swift-insight-normalization-fast-paths`** (merge to **`main`** and tag or pin per your release process). This specification summary should accompany or follow that merge for traceability.

---

## Related specifications

- **`specifications/summary/OGT-SWIFT-PACKAGE-COMPLETION-SUMMARY.md`** — SPM layout and public pipeline API.  
- **`specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md`** — TypeScript ↔ Swift parity expectations.  
- **GlucoseAITracker** **`GLUCOSE-PERF-LAUNCH-INSIGHTS-COMPLETION-SUMMARY.md`** — end-to-end performance work including app wiring to **`ogtNormalizeCanonicalReadingTrustedMillisEncodedRFC3339`**.
