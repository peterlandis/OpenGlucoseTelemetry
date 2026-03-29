# OGT MVP dev harness

## Prerequisites

- Node.js 20+
- [pnpm](https://pnpm.io/) (Corepack: `corepack enable`)

Install dependencies from the repository root:

```bash
pnpm install
pnpm build
```

The CLI runs compiled JavaScript under `dist/`. After changing TypeScript sources, run `pnpm build` again (or use `pnpm pipeline:dev` with `tsx` during development).

## Run the pipeline on a sample envelope

```bash
pnpm pipeline examples/ingestion/healthkit-sample.json
```

Prints canonical `glucose.reading` JSON to stdout.

## Exit codes

| Code | Meaning |
|------|--------|
| 0 | Success; canonical JSON written to stdout |
| 1 | Pipeline error; structured error JSON on stderr |
| 2 | Usage error, missing file, or invalid JSON |

## Tests

```bash
pnpm test
```
