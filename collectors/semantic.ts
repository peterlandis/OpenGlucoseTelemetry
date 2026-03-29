import type { CanonicalGlucoseReadingV01 } from "./normalize.js";
import type { StructuredPipelineError } from "./errors.js";
import { err } from "./errors.js";

/** Clock skew window for future observed_at (OGIS time-semantics; OGT policy). */
export const FUTURE_SKEW_MS: number = 15 * 60 * 1000;

const MGDL_MIN: number = 20;
const MGDL_MAX: number = 600;

export function applySemanticRules(
  reading: CanonicalGlucoseReadingV01,
  traceId: string,
): StructuredPipelineError | null {
  const now: number = Date.now();
  const observedMs: number = Date.parse(reading.observed_at);
  if (Number.isNaN(observedMs)) {
    return err("SEMANTIC_INVALID", "observed_at is not parseable", traceId, "observed_at");
  }
  if (observedMs > now + FUTURE_SKEW_MS) {
    return err(
      "SEMANTIC_INVALID",
      "observed_at is too far in the future (> 15 minutes)",
      traceId,
      "observed_at",
    );
  }

  if (reading.unit !== "mg/dL") {
    return err(
      "SEMANTIC_INVALID",
      "Expected normalized unit mg/dL before semantic glucose range check",
      traceId,
      "unit",
    );
  }

  if (reading.value < MGDL_MIN || reading.value > MGDL_MAX) {
    return err(
      "SEMANTIC_INVALID",
      `Glucose value out of plausible range for mg/dL (${MGDL_MIN}–${MGDL_MAX})`,
      traceId,
      "value",
    );
  }

  if (reading.source_recorded_at !== undefined) {
    const sr: number = Date.parse(reading.source_recorded_at);
    if (Number.isNaN(sr)) {
      return err("SEMANTIC_INVALID", "source_recorded_at is not parseable", traceId, "source_recorded_at");
    }
    if (sr > now + FUTURE_SKEW_MS) {
      return err(
        "SEMANTIC_INVALID",
        "source_recorded_at is too far in the future (> 15 minutes)",
        traceId,
        "source_recorded_at",
      );
    }
  }

  return null;
}
