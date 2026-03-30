import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

function findRepoRoot(startDir: string): string {
  let dir: string = startDir;
  for (let i: number = 0; i < 12; i += 1) {
    const marker: string = join(dir, "spec", "ingestion-envelope.schema.json");
    if (existsSync(marker)) {
      return dir;
    }
    const parent: string = join(dir, "..");
    if (parent === dir) {
      break;
    }
    dir = parent;
  }
  throw new Error("Could not locate OGT repo root (missing spec/ingestion-envelope.schema.json). Run from the repository root.");
}

const collectorsDir: string = dirname(fileURLToPath(import.meta.url));
export const specPaths = {
  repoRoot: findRepoRoot(collectorsDir),
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
