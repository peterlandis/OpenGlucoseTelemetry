# OGT runtimes

Each subdirectory is a **language or platform runtime** that implements the OGT ingestion and normalization pipeline against the shared contracts at the repository root:

- [`spec/`](../spec/) — JSON Schemas and pinned OGIS
- [`examples/`](../examples/) — golden fixtures for cross-runtime tests

**Every runtime must provide `collectors/` and `adapters/`** with the same responsibilities. **[`RUNTIME-TEMPLATE.md`](./RUNTIME-TEMPLATE.md)** defines the **pipeline layers**, data flow, and the **checklist for adding a new provider (`source`)** or a **new language**.

---

## Pipeline layers (MVP)

End-to-end processing is split into **collectors** (orchestration) and **adapters** (per-source mapping). Collectors run these stages in order:

1. **Ingress** — envelope input (JSON / decode).
2. **Envelope validation** — schema or equivalent rules on the wrapper.
3. **Payload validation** — per-`source` rules on `payload`.
4. **Adapter map** — `adapters/<source>/` → pre-normalize canonical reading.
5. **Normalize** — timestamps, mg/dL, string bounds.
6. **Semantic rules** — policy (range, clock skew, etc.).
7. **Dedupe (optional)** — duplicate detection.
8. **OGIS validation** — pinned `glucose.reading` v0.1.
9. **Result** — success canonical or structured failure.

Full table and diagrams: **[`RUNTIME-TEMPLATE.md`](./RUNTIME-TEMPLATE.md)**.

---

## Adding a new provider

Pick a stable **`source`** string, add **`spec/<source>-payload.schema.json`**, golden files under **`examples/`**, then implement **adapter + collector routing** in **each** runtime you maintain (TypeScript and Swift today). Step-by-step: **[`RUNTIME-TEMPLATE.md` § Adding a new provider](./RUNTIME-TEMPLATE.md#adding-a-new-provider-source)**.

---

## Runtimes

| Runtime | Status | Notes |
|---------|--------|--------|
| [`typescript/`](./typescript/) | **Reference** (MVP) | Node: layered `collectors/` (see [`collectors/README.md`](./typescript/collectors/README.md)), `adapters/`, `dev/` CLI; `pnpm` package `@openglucose/telemetry-mvp`; [`README.md`](./typescript/README.md), [`ARCHITECTURE.md`](./typescript/ARCHITECTURE.md) |
| [`swift/`](./swift/) | **MVP parity** with TS `submit` | SPM: `OpenGlucoseTelemetryRuntime`; [`README.md`](./swift/README.md), [`ARCHITECTURE.md`](./swift/ARCHITECTURE.md), [`examples/RunPipelineExample`](./swift/examples/) |

Adding another language (Kotlin, Rust, …): new folder under `runtimes/<name>/`, same **layers** as [`RUNTIME-TEMPLATE.md`](./RUNTIME-TEMPLATE.md), register here.
