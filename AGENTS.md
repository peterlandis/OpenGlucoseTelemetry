# AGENTS.md

## Cursor Cloud specific instructions

### Overview

Open Glucose Telemetry (OGT) is a pure data-transformation pipeline library (no running servers, databases, or HTTP APIs). The TypeScript runtime under `runtimes/typescript/` is the primary development target on this VM. The Swift runtime (`runtimes/swift/`) requires macOS and is not buildable in this Linux environment.

### Quick reference

| Action | Command (from repo root) |
|--------|--------------------------|
| Install deps | `pnpm install` |
| Build | `pnpm build` |
| Type-check | `pnpm typecheck` |
| Run tests | `pnpm test` |
| Run pipeline | `pnpm pipeline examples/ingestion/healthkit-sample.json` |
| Full smoke | `pnpm verify` (build + test + pipeline on both sample fixtures) |
| Dev pipeline (no build) | `pnpm pipeline:dev -- <path-to-envelope.json>` (uses `tsx`) |

### Non-obvious notes

- **No external services needed.** There are no databases, Docker containers, message brokers, or environment variables. Everything runs in-process.
- **`pnpm build` must run before `pnpm pipeline`** because the CLI entry point (`dist/dev/run-pipeline.js`) requires compiled output. Use `pnpm pipeline:dev` to skip the build step during development (it uses `tsx` for on-the-fly TS execution).
- **Schema sync on build.** The `prebuild` script (`sync-schemas`) copies JSON schemas from `spec/` into `runtimes/typescript/bundled/spec/`. This runs automatically with `pnpm build`. If you edit schemas in `spec/`, rebuild to pick up changes.
- **Node.js >= 20 required.** The `engines` field in `runtimes/typescript/package.json` enforces this. The VM has Node 22 via nvm.
- **pnpm 9.15.0 pinned via Corepack.** The root `package.json` `packageManager` field pins the exact version.
- **Test runner is Vitest.** Tests live alongside source in `runtimes/typescript/` (e.g., `adapters/dexcom/map.test.ts`, `collectors/pipeline.test.ts`). Run with `pnpm test` or `pnpm test:watch` for watch mode.
- **Golden test fixtures** in `examples/` are language-neutral: `examples/ingestion/` has input envelopes, `examples/canonical/` has expected outputs. Both runtimes must produce matching results.
