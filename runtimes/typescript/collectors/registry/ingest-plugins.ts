/**
 * Pluggable per-source **validate + map**. Add an entry to `builtinIngestPlugins` when adding
 * `adapters/<source>/`; do **not** add `if (env.source === …)` branches to `collector-engine.ts`.
 */
import type { ValidateFunction } from "ajv";
import type { IngestionEnvelope } from "../ingestion/ingestion-types.js";
import type { CanonicalGlucoseReadingV01 } from "../canonical/canonical-glucose-reading.js";
import {
  formatAjvErrors,
  validateDexcomPayload,
  validateHealthkitPayload,
  validateMockPayload,
} from "../validation/schema-validators.js";
import { mapHealthKitPayloadToCanonical, type HealthKitGlucosePayload } from "../../adapters/healthkit/map.js";
import { mapMockPayloadToCanonical, type MockGlucosePayload } from "../../adapters/mock/map.js";
import { mapDexcomPayloadToCanonical, type DexcomGlucosePayload } from "../../adapters/dexcom/map.js";

export type SourceIngestPlugin = {
  validatePayload(payload: unknown): boolean;
  payloadValidationErrors(): string;
  mapToCanonical(payload: Record<string, unknown>, env: IngestionEnvelope): CanonicalGlucoseReadingV01;
};

function ajvPlugin(
  validate: ValidateFunction,
  map: (payload: Record<string, unknown>, env: IngestionEnvelope) => CanonicalGlucoseReadingV01,
): SourceIngestPlugin {
  return {
    validatePayload(payload: unknown): boolean {
      return validate(payload);
    },
    payloadValidationErrors(): string {
      return formatAjvErrors(validate.errors);
    },
    mapToCanonical(payload: Record<string, unknown>, env: IngestionEnvelope): CanonicalGlucoseReadingV01 {
      return map(payload, env);
    },
  };
}

/** Built-in MVP sources. Append when adding a new adapter + schema. */
export const builtinIngestPlugins: Record<string, SourceIngestPlugin> = {
  healthkit: ajvPlugin(validateHealthkitPayload, (payload, env) =>
    mapHealthKitPayloadToCanonical(payload as unknown as HealthKitGlucosePayload, env),
  ),
  mock: ajvPlugin(validateMockPayload, (payload, env) =>
    mapMockPayloadToCanonical(payload as unknown as MockGlucosePayload, env),
  ),
  dexcom: ajvPlugin(validateDexcomPayload, (payload, env) =>
    mapDexcomPayloadToCanonical(payload as unknown as DexcomGlucosePayload, env),
  ),
};
