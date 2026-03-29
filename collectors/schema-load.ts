import { readFileSync } from "node:fs";

export function loadJsonSchema(path: string): object {
  const raw: string = readFileSync(path, "utf8");
  const parsed: unknown = JSON.parse(raw);
  if (typeof parsed !== "object" || parsed === null) {
    throw new Error(`Invalid JSON schema at ${path}`);
  }
  return parsed as object;
}
