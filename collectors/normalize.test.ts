import { describe, expect, it } from "vitest";
import { MGDL_PER_MMOL, normalizeGlucoseToMgdl, normalizeTimestamp } from "./normalize.js";

describe("normalize (OGIS unit alignment)", () => {
  it("uses OGIS mg/dL per mmol/L factor 18.018", () => {
    expect(MGDL_PER_MMOL).toBe(18.018);
  });

  it("converts mmol/L to mg/dL with 18.018 and one-decimal rounding", () => {
    const out = normalizeGlucoseToMgdl(5.5, "mmol/L");
    expect(out.unit).toBe("mg/dL");
    expect(out.value).toBe(Math.round(5.5 * 18.018 * 10) / 10);
  });

  it("normalizes RFC3339 to UTC ISO with ms", () => {
    const s = normalizeTimestamp("2026-03-29T14:32:00.000Z");
    expect(s).toBe("2026-03-29T14:32:00.000Z");
  });
});
