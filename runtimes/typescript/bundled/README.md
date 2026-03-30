# Bundled JSON schemas

This directory holds a **copy** of the OGT JSON Schemas from the repository `spec/` tree (`ingestion-envelope`, per-source payloads, pinned OGIS `glucose.reading`). It exists so **`@openglucose/telemetry-runtime`** can run **`submit()`** after installation from npm without a full **OpenGlucoseTelemetry** checkout.

Refresh from the repo root with:

```bash
pnpm run sync-schemas
```

(`prebuild` runs this automatically before `tsc`.)
