# OGT MVP dev harness (Node / TypeScript runtime)

This folder belongs to [`runtimes/typescript`](../). Commands below are written for running **from the repository root** (recommended), which keeps paths to `examples/` stable.

## Prerequisites

- Node.js 20+ locally; GitHub Actions CI uses **Node.js 24** (see `.github/workflows/ogt-mvp-ci.yml`).
- [pnpm](https://pnpm.io/) (Corepack: `corepack enable`)

Install and build from the repository root:

```bash
pnpm install
pnpm build
```

The CLI runs compiled JavaScript under `runtimes/typescript/dist/`. After changing TypeScript sources, run `pnpm build` again (or use `pnpm pipeline:dev` with `tsx` during development).

## Run the pipeline on a sample envelope

From the repository root (after `pnpm build`):

```bash
pnpm pipeline examples/ingestion/healthkit-sample.json
pnpm pipeline examples/ingestion/dexcom-sample.json
```

When working only inside `runtimes/typescript`, use paths relative to that package, for example:

```bash
pnpm pipeline ../../examples/ingestion/healthkit-sample.json
```

Prints canonical `glucose.reading` JSON to stdout.

## Exit codes

| Code | Meaning |
|------|--------|
| 0 | Success; canonical JSON written to stdout |
| 1 | Pipeline error; structured error JSON on stderr |
| 2 | Usage error, missing file, or invalid JSON |

## Tests

From the repository root:

```bash
pnpm test
```

## Cross-runtime JSON parity

Compare two canonical JSON files with stable key ordering (e.g. TS `pnpm pipeline` output vs Swift export):

```bash
pnpm parity:check path/to/a.json path/to/b.json
```

See [`examples/canonical/README.md`](../../../examples/canonical/README.md).
