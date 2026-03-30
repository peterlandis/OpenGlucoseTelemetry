# TypeScript runtime — npm package completion summary

This document summarizes how the **OpenGlucoseTelemetry** TypeScript runtime is published and consumed as **`@openglucose/telemetry-runtime`**.

## Deliverable

- **Package name:** `@openglucose/telemetry-runtime` (see `runtimes/typescript/package.json`).
- **Entry:** ESM **`exports["."]`** → `dist/collectors/pipeline.js` with TypeScript declarations (`declaration` + `declarationMap` in `tsconfig.build.json`).
- **Runtime dependencies:** `ajv`, `ajv-formats` (JSON Schema validation).
- **Bundled schemas:** `runtimes/typescript/bundled/spec/` mirrors the repo `spec/` files required by `collectors/validation/schema-validators.ts`, including `pinned/glucose.reading.v0_1.json`. Refreshed by **`pnpm run sync-schemas`** (`scripts/sync-schemas.mjs`), invoked in **`prebuild`** before `tsc`.
- **Publish:** `private` removed; `files` includes `dist`, `bundled`, `README.md`; `publishConfig.access: public` for the `@openglucose` scope.

## Path resolution (`specPaths`)

`collectors/tooling/paths.ts` resolves schema locations for:

1. **Monorepo / full checkout:** first directory (walking upward from the compiled `tooling` module) that contains both **`spec/ingestion-envelope.schema.json`** and an **`examples/`** directory — so Vitest golden tests can read **`examples/ingestion/*.json`** via `specPaths.repoRoot`.
2. **Installed npm package:** if no such repo root exists, fall back to **`bundled/`** next to the package root so **`submit()`** works with only the published tarball.

## Verification

From **`runtimes/typescript/`**:

```bash
pnpm install
pnpm build
pnpm test
```

From the **OpenGlucoseTelemetry** repo root (workspace):

```bash
pnpm build
pnpm test
```

## Documentation for consumers

Install and usage examples: **[`runtimes/typescript/README.md`](../../runtimes/typescript/README.md)** (**Installing and using**).

## Related docs

- [`runtimes/typescript/README.md`](../../runtimes/typescript/README.md) — pipeline overview, build, tests
- [`specifications/summary/OGT-SWIFT-PACKAGE-COMPLETION-SUMMARY.md`](./OGT-SWIFT-PACKAGE-COMPLETION-SUMMARY.md) — Swift Package counterpart
- [`specifications/handoff/OGT-SWIFT-PARITY-MATRIX.md`](../handoff/OGT-SWIFT-PARITY-MATRIX.md) — TS ↔ Swift parity
