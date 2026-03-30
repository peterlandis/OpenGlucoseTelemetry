# Swift runtime examples

## `RunPipelineExample` (executable)

Demonstrates the **collector + adapters** path:

1. Load an **ingestion envelope** JSON (same shape as `spec/ingestion-envelope.schema.json`).
2. Call **`OGTReferenceCollector().submit(envelope:)`**.
3. Print **pretty-printed canonical** `glucose.reading` JSON on success, or **structured error** fields on stderr on failure.

### How to run

From **`runtimes/swift`**, with the full **OpenGlucoseTelemetry** checkout (so `../../spec` and `../../examples` exist):

**Default fixture** (repo `examples/ingestion/healthkit-sample.json`, resolved via `OGTRepositoryRoot` from your current working directory):

```bash
cd runtimes/swift
swift run RunPipelineExample
```

**Your own envelope file:**

```bash
swift run RunPipelineExample /path/to/ingestion-envelope.json
```

**After building:**

```bash
swift build -c release
.build/release/RunPipelineExample
.build/release/RunPipelineExample ../../examples/ingestion/dexcom-sample.json
```

Exit codes: **0** success, **1** pipeline failure, **2** I/O or decode error.

### Requirements

- Working directory must be **inside** the OpenGlucoseTelemetry tree (or a parent path that contains `spec/ingestion-envelope.schema.json`) when using the **no-argument** default, so `OGTRepositoryRoot` can find the repo root.

See also: package **[`README.md`](../README.md)** and **[`ARCHITECTURE.md`](../ARCHITECTURE.md)**.
