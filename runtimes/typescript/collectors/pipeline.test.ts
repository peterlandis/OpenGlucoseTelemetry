import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import { submit } from "./pipeline.js";
import { DedupeTracker } from "./normalization/dedupe.js";
import { normalizeTimestamp, normalizeGlucoseToMgdl } from "./normalization/normalize.js";
import { specPaths } from "./tooling/paths.js";

const root: string = specPaths.repoRoot;

function readExample(rel: string): unknown {
  const raw: string = readFileSync(join(root, rel), "utf8");
  return JSON.parse(raw) as unknown;
}

describe("submit pipeline", () => {
  it("passes healthkit golden fixture", () => {
    const envelope: unknown = readExample("examples/ingestion/healthkit-sample.json");
    const expected: unknown = readExample("examples/canonical/healthkit-sample.expected.json");
    const result = submit(envelope);
    expect(result.ok).toBe(true);
    if (!result.ok) {
      return;
    }
    expect(result.value).toEqual(expected);
  });

  it("passes dexcom golden fixture", () => {
    const envelope: unknown = readExample("examples/ingestion/dexcom-sample.json");
    const expected: unknown = readExample("examples/canonical/dexcom-sample.expected.json");
    const result = submit(envelope);
    expect(result.ok).toBe(true);
    if (!result.ok) {
      return;
    }
    expect(result.value).toEqual(expected);
  });

  it("passes mock adapter envelope", () => {
    const envelope = {
      source: "mock",
      payload: {
        subject_id: "local:mock:1",
        value: 5.5,
        unit: "mmol/L",
        observed_at: "2026-03-29T10:00:00.000Z",
      },
      received_at: "2026-03-29T10:00:01.000Z",
      trace_id: "trace-mock-1",
      adapter: { id: "ogt.adapter.mock", version: "0.1.0" },
    };
    const result = submit(envelope);
    expect(result.ok).toBe(true);
    if (!result.ok) {
      return;
    }
    expect(result.value.unit).toBe("mg/dL");
    expect(result.value.value).toBeCloseTo(99.1, 5);
    expect(result.value.measurement_source).toBe("manual");
  });

  it("rejects unknown adapter source with stable code", () => {
    const envelope = {
      source: "vendor-unknown",
      payload: {},
      received_at: "2026-03-29T10:00:00.000Z",
      trace_id: "t1",
      adapter: { id: "x", version: "1.0.0" },
    };
    const result = submit(envelope);
    expect(result.ok).toBe(false);
    if (result.ok) {
      return;
    }
    expect(result.error.code).toBe("ADAPTER_UNKNOWN");
    expect(result.error.trace_id).toBe("t1");
  });

  it("rejects invalid envelope with ENVELOPE_INVALID", () => {
    const envelope = {
      source: "healthkit",
      payload: {},
      received_at: "not-a-date",
      trace_id: "",
      adapter: { id: "a", version: "1" },
    };
    const result = submit(envelope);
    expect(result.ok).toBe(false);
    if (result.ok) {
      return;
    }
    expect(result.error.code).toBe("ENVELOPE_INVALID");
  });

  it("rejects bad healthkit payload with PAYLOAD_INVALID", () => {
    const envelope = {
      source: "healthkit",
      payload: { uuid: "x", value: 100, unit: "mg/dL" },
      received_at: "2026-03-29T10:00:00.000Z",
      trace_id: "t2",
      adapter: { id: "ogt.adapter.healthkit", version: "0.1.0" },
    };
    const result = submit(envelope);
    expect(result.ok).toBe(false);
    if (result.ok) {
      return;
    }
    expect(result.error.code).toBe("PAYLOAD_INVALID");
  });

  it("rejects future observed_at with SEMANTIC_INVALID", () => {
    const farFuture: string = new Date(Date.now() + 60 * 60 * 1000).toISOString();
    const envelope = {
      source: "mock",
      payload: {
        subject_id: "s",
        value: 100,
        unit: "mg/dL",
        observed_at: farFuture,
      },
      received_at: "2026-03-29T10:00:00.000Z",
      trace_id: "t3",
      adapter: { id: "ogt.adapter.mock", version: "0.1.0" },
    };
    const result = submit(envelope);
    expect(result.ok).toBe(false);
    if (result.ok) {
      return;
    }
    expect(result.error.code).toBe("SEMANTIC_INVALID");
    expect(result.error.field).toBe("observed_at");
  });

  it("rejects out-of-range glucose with SEMANTIC_INVALID", () => {
    const envelope = {
      source: "mock",
      payload: {
        subject_id: "s",
        value: 900,
        unit: "mg/dL",
        observed_at: "2026-03-29T10:00:00.000Z",
      },
      received_at: "2026-03-29T10:00:00.000Z",
      trace_id: "t4",
      adapter: { id: "ogt.adapter.mock", version: "0.1.0" },
    };
    const result = submit(envelope);
    expect(result.ok).toBe(false);
    if (result.ok) {
      return;
    }
    expect(result.error.code).toBe("SEMANTIC_INVALID");
    expect(result.error.field).toBe("value");
  });

  it("returns DUPLICATE_EVENT when dedupe enabled", () => {
    const envelope = readExample("examples/ingestion/healthkit-sample.json");
    const dedupe: DedupeTracker = new DedupeTracker();
    const first = submit(envelope, { dedupe });
    const second = submit(envelope, { dedupe });
    expect(first.ok).toBe(true);
    expect(second.ok).toBe(false);
    if (second.ok) {
      return;
    }
    expect(second.error.code).toBe("DUPLICATE_EVENT");
  });
});

describe("normalizeTimestamp (DST-safe)", () => {
  it("normalizes Zulu instants", () => {
    expect(normalizeTimestamp("2026-03-29T14:32:00.000Z")).toBe("2026-03-29T14:32:00.000Z");
  });
});

describe("normalizeGlucoseToMgdl", () => {
  it("converts mmol/L using OGIS factor", () => {
    const r = normalizeGlucoseToMgdl(5.5, "mmol/L");
    expect(r.unit).toBe("mg/dL");
    expect(r.value).toBeCloseTo(99.1, 5);
  });
});

describe("negative fixtures", () => {
  const cases: { file: string; code: string }[] = [
    { file: "examples/ingestion/negative-healthkit-bad-unit.json", code: "PAYLOAD_INVALID" },
    { file: "examples/ingestion/negative-healthkit-future.json", code: "SEMANTIC_INVALID" },
    { file: "examples/ingestion/negative-healthkit-out-of-range.json", code: "SEMANTIC_INVALID" },
    { file: "examples/ingestion/negative-mock-bad-observed.json", code: "PAYLOAD_INVALID" },
  ];

  it.each(cases)("rejects $file with $code", ({ file, code }) => {
    const envelope: unknown = readExample(file);
    const result = submit(envelope);
    expect(result.ok).toBe(false);
    if (result.ok) {
      return;
    }
    expect(result.error.code).toBe(code);
    expect(result.error.trace_id.length).toBeGreaterThan(0);
  });
});
