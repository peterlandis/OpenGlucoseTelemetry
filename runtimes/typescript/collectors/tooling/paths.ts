import { existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

/**
 * Resolves the directory used as the root for `spec/…` schema paths (and `examples/…` when present).
 *
 * 1. **Full OpenGlucoseTelemetry checkout:** walk upward until both `spec/ingestion-envelope.schema.json` and an `examples/` directory exist (so tests can read golden fixtures).
 * 2. **Published npm package:** if no such repo root is found, use the nearest `bundled/` folder that contains `spec/ingestion-envelope.schema.json` (schemas only; no `examples/` in the tarball).
 */
function findSpecRoot(startDir: string): string {
  let dir: string = resolve(startDir);
  let bundledFallback: string | null = null;
  for (let i: number = 0; i < 16; i += 1) {
    const fullSpecMarker: string = join(dir, "spec", "ingestion-envelope.schema.json");
    const examplesDir: string = join(dir, "examples");
    if (existsSync(fullSpecMarker) && existsSync(examplesDir)) {
      return dir;
    }
    const bundledMarker: string = join(dir, "bundled", "spec", "ingestion-envelope.schema.json");
    if (existsSync(bundledMarker) && bundledFallback === null) {
      bundledFallback = join(dir, "bundled");
    }
    const parent: string = resolve(dir, "..");
    if (parent === dir) {
      break;
    }
    dir = parent;
  }
  if (bundledFallback !== null) {
    return bundledFallback;
  }
  throw new Error(
    "Could not locate OGT JSON schemas (expected a repo checkout with spec/ and examples/, or bundled/spec/ in the published package).",
  );
}

const toolingDir: string = dirname(fileURLToPath(import.meta.url));
export const specPaths = {
  repoRoot: findSpecRoot(toolingDir),
  get ingestionEnvelopeSchema(): string {
    return join(this.repoRoot, "spec/ingestion-envelope.schema.json");
  },
  get healthkitPayloadSchema(): string {
    return join(this.repoRoot, "spec/healthkit-payload.schema.json");
  },
  get mockPayloadSchema(): string {
    return join(this.repoRoot, "spec/mock-payload.schema.json");
  },
  get dexcomPayloadSchema(): string {
    return join(this.repoRoot, "spec/dexcom-payload.schema.json");
  },
  get glucoseReadingOgisSchema(): string {
    return join(this.repoRoot, "spec/pinned/glucose.reading.v0_1.json");
  },
} as const;
