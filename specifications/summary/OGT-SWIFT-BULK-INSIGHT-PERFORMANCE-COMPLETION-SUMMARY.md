# OGT Swift runtime — Bulk insight / RFC3339 performance — Completion summary

**Package:** `runtimes/swift` → product **OpenGlucoseTelemetryRuntime**  
**Embedder reference (full stack):** `GlucoseAITracker/specifications/summary/GLUCOSE-PERF-LAUNCH-INSIGHTS-COMPLETION-SUMMARY.md`  
**Last updated:** 2026-04-08

---

## Executive summary

Embeddable apps that **re-validate** many persisted canonical readings (chart/insight gating) were paying **redundant ICU cost**: timestamps were emitted with **`OGTRFC3339.encodeMillisUTC`** then **re-parsed** inside **`ogtNormalizeCanonicalReading`** and again in **`ogtApplySemanticRules`** / **`ogtValidateGlucoseReadingOgis`** via **`OGTRFC3339.epochMs`** → **`decode`**.

This slice adds:

1. **`ogtNormalizeCanonicalReadingTrustedMillisEncodedRFC3339`** — skips **`ogtNormalizeTimestamp`** when timestamps are already trusted **`encodeMillisUTC`** output; keeps mg/dL and string-bound behavior aligned with **`ogtNormalizeCanonicalReading`** for that case (tests enforce parity).
2. **ASCII fast path in `OGTRFC3339.decode` / `epochMs`** for common UTC Zulu shapes (24- and 20-character forms) before **`ISO8601DateFormatter`**.

---

## Key files

| Path | Role |
|------|------|
| `Sources/.../normalization/OGTNormalizer.swift` | Trusted normalizer API |
| `Sources/.../normalization/OGTRFC3339.swift` | `decode` / `epochMs` fast path |
| `Tests/.../OGTCollectorPipelineTests.swift` | Parity + round-trip tests |
| `Sources/.../collectors/README.md` | “Performance: bulk re-validation” embedder guidance |
| `runtimes/swift/README.md` | Integration note |

---

## Public API (new / behavior)

- **`ogtNormalizeCanonicalReadingTrustedMillisEncodedRFC3339(reading:envelopeReceivedAt:)`** — **public**; caller contract documented in **`collectors/README.md`**.
- **`OGTRFC3339.decode` / `epochMs`** — same signatures; **faster** for normalized Zulu strings.

**Ingest path unchanged:** **`OGTCollectorEngine`** continues to use **`ogtNormalizeCanonicalReading`** for arbitrary wire input.

---

## Verification

```bash
cd runtimes/swift && swift test
```

---

## Git

Performance + docs were committed on branch **`perf/swift-insight-normalization-fast-paths`** (merge to **`main`** per your release process).
