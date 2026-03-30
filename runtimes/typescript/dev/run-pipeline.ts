#!/usr/bin/env node
import { readFileSync } from "node:fs";
import { submit } from "../collectors/pipeline.js";

const path: string | undefined = process.argv[2];
if (path === undefined || path.length === 0) {
  console.error("Usage: pnpm pipeline <path-to-ingestion-envelope.json>");
  process.exit(2);
}

let raw: string;
try {
  raw = readFileSync(path, "utf8");
} catch (e) {
  console.error(`Failed to read file: ${path}`, e);
  process.exit(2);
}

let envelope: unknown;
try {
  envelope = JSON.parse(raw) as unknown;
} catch (e) {
  console.error("Invalid JSON", e);
  process.exit(2);
}

const result = submit(envelope);
if (!result.ok) {
  console.error(JSON.stringify(result.error, null, 2));
  process.exit(1);
}

process.stdout.write(`${JSON.stringify(result.value, null, 2)}\n`);
process.exit(0);
