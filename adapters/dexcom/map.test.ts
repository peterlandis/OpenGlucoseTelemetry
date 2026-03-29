import { describe, expect, it } from "vitest";
import { mapDexcomTrendArrowToDirection } from "./map.js";

describe("mapDexcomTrendArrowToDirection", () => {
  it("maps rising tokens", () => {
    expect(mapDexcomTrendArrowToDirection("singleUp")).toBe("rising");
    expect(mapDexcomTrendArrowToDirection("doubleUp")).toBe("rising");
    expect(mapDexcomTrendArrowToDirection("fortyFiveUp")).toBe("rising");
  });

  it("maps falling tokens", () => {
    expect(mapDexcomTrendArrowToDirection("singleDown")).toBe("falling");
    expect(mapDexcomTrendArrowToDirection("doubleDown")).toBe("falling");
    expect(mapDexcomTrendArrowToDirection("fortyFiveDown")).toBe("falling");
  });

  it("maps stable tokens", () => {
    expect(mapDexcomTrendArrowToDirection("flat")).toBe("stable");
    expect(mapDexcomTrendArrowToDirection("none")).toBe("stable");
  });

  it("maps unknown and empty", () => {
    expect(mapDexcomTrendArrowToDirection(undefined)).toBe("unknown");
    expect(mapDexcomTrendArrowToDirection("notComputable")).toBe("unknown");
    expect(mapDexcomTrendArrowToDirection("customVendor")).toBe("unknown");
  });
});
