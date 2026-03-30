#!/usr/bin/env node
/**
 * Stable JSON equality check for cross-runtime golden comparison.
 * Usage: node dev/parity-check.mjs <path-a.json> <path-b.json>
 */
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

function stableStringify(value) {
  if (value === null || typeof value !== "object") {
    return JSON.stringify(value);
  }
  if (Array.isArray(value)) {
    return `[${value.map((v) => stableStringify(v)).join(",")}]`;
  }
  const keys = Object.keys(value).sort();
  const parts = keys.map((k) => `${JSON.stringify(k)}:${stableStringify(value[k])}`);
  return `{${parts.join(",")}}`;
}

const aPath = process.argv[2];
const bPath = process.argv[3];
if (aPath === undefined || bPath === undefined) {
  console.error("Usage: node dev/parity-check.mjs <file-a.json> <file-b.json>");
  process.exit(2);
}

const aRaw = readFileSync(resolve(aPath), "utf8");
const bRaw = readFileSync(resolve(bPath), "utf8");
const aJson = JSON.parse(aRaw);
const bJson = JSON.parse(bRaw);
const aStr = stableStringify(aJson);
const bStr = stableStringify(bJson);

if (aStr !== bStr) {
  console.error("JSON documents differ (stable key-sorted comparison).");
  process.exit(1);
}

console.log("OK: JSON documents are equal (stable comparison).");
process.exit(0);
