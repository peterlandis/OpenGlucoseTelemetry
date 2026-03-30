#!/usr/bin/env node
/**
 * Copies OGT JSON schemas from the repo `spec/` tree into `bundled/spec/` so the
 * published npm package can validate envelopes without a full OpenGlucoseTelemetry checkout.
 */
import { cpSync, mkdirSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const tsRoot = join(__dirname, "..");
const repoSpec = join(tsRoot, "..", "..", "spec");
const destRoot = join(tsRoot, "bundled", "spec");

if (!existsSync(repoSpec)) {
  console.error(`sync-schemas: expected repo spec at ${repoSpec}`);
  process.exit(1);
}

mkdirSync(join(destRoot, "pinned"), { recursive: true });

const files = [
  "ingestion-envelope.schema.json",
  "healthkit-payload.schema.json",
  "mock-payload.schema.json",
  "dexcom-payload.schema.json",
];

for (const name of files) {
  const src = join(repoSpec, name);
  const dst = join(destRoot, name);
  if (!existsSync(src)) {
    console.error(`sync-schemas: missing ${src}`);
    process.exit(1);
  }
  cpSync(src, dst);
}

const pinned = "pinned/glucose.reading.v0_1.json";
cpSync(join(repoSpec, pinned), join(destRoot, pinned));

console.log(`sync-schemas: copied spec → ${destRoot}`);
