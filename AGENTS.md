# AGENTS.md

## Cursor Cloud specific instructions

This is a **pnpm monorepo** (single workspace package under `runtimes/typescript/`) for the Open Glucose Telemetry (OGT) project — a library/SDK with no external service dependencies (no Docker, no databases, no HTTP servers).

### Key commands (all from repo root)

| Action | Command |
|--------|---------|
| Install deps | `pnpm install --frozen-lockfile` |
| Build (TS compile) | `pnpm build` |
| Type-check | `pnpm typecheck` |
| Run tests | `pnpm test` |
| Full verify (build + test + smoke) | `pnpm verify` |
| Run pipeline on a fixture | `pnpm pipeline examples/ingestion/healthkit-sample.json` |

### Notes

- **Node.js >= 20** is required; the CI uses Node 24 but 20+ works fine locally.
- **pnpm 9.15.0** is pinned via the `packageManager` field in `package.json` (Corepack-compatible).
- The `prebuild` script automatically syncs JSON schemas from `spec/` into `runtimes/typescript/bundled/spec/` — no manual step needed.
- There is **no ESLint or Prettier** configured; `pnpm typecheck` (`tsc --noEmit`) is the primary lint-equivalent check.
- The **Swift runtime** (`runtimes/swift/`) requires a Swift toolchain (typically macOS); it is not expected to build on Linux cloud VMs.
- Tests use **vitest** and run in under 1 second. All golden fixtures are in `examples/`.
- `pnpm verify` is the CI-equivalent command — it builds, tests, and smoke-runs the pipeline on both sample fixtures.
