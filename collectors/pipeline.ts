import type { PipelineResult, StructuredPipelineError } from "./errors.js";
import { failure } from "./errors.js";
import {
  formatAjvErrors,
  validateDexcomPayload,
  validateEnvelope,
  validateGlucoseReadingOgis,
  validateHealthkitPayload,
  validateMockPayload,
} from "./validators.js";
import type { CanonicalGlucoseReadingV01 } from "./normalize.js";
import { normalizeCanonicalReading } from "./normalize.js";
import { applySemanticRules } from "./semantic.js";
import { mapHealthKitPayloadToCanonical, type HealthKitGlucosePayload } from "../adapters/healthkit/map.js";
import { mapMockPayloadToCanonical, type MockGlucosePayload } from "../adapters/mock/map.js";
import { mapDexcomPayloadToCanonical, type DexcomGlucosePayload } from "../adapters/dexcom/map.js";
import { DedupeTracker } from "./dedupe.js";

export type IngestionEnvelope = {
  source: string;
  payload: Record<string, unknown>;
  received_at: string;
  trace_id: string;
  adapter: { id: string; version: string };
};

export type SubmitOptions = {
  dedupe?: DedupeTracker;
};

/**
 * End-to-end MVP pipeline: envelope → adapter map → normalize → semantic rules → OGIS JSON Schema.
 */
export function submit(
  envelope: unknown,
  options?: SubmitOptions,
): PipelineResult<CanonicalGlucoseReadingV01> {
  const traceFallback: string =
    typeof envelope === "object" && envelope !== null && "trace_id" in envelope && typeof (envelope as { trace_id: unknown }).trace_id === "string"
      ? ((envelope as { trace_id: string }).trace_id as string)
      : "unknown";

  if (!validateEnvelope(envelope)) {
    return failure(
      "ENVELOPE_INVALID",
      formatAjvErrors(validateEnvelope.errors),
      traceFallback,
    );
  }

  const env: IngestionEnvelope = envelope as IngestionEnvelope;
  const traceId: string = env.trace_id;

  if (env.source === "healthkit") {
    if (!validateHealthkitPayload(env.payload)) {
      return failure(
        "PAYLOAD_INVALID",
        formatAjvErrors(validateHealthkitPayload.errors),
        traceId,
      );
    }
    const mapped: CanonicalGlucoseReadingV01 = mapHealthKitPayloadToCanonical(
      env.payload as unknown as HealthKitGlucosePayload,
      env,
    );
    return finalize(mapped, env, traceId, options);
  }

  if (env.source === "mock") {
    if (!validateMockPayload(env.payload)) {
      return failure(
        "PAYLOAD_INVALID",
        formatAjvErrors(validateMockPayload.errors),
        traceId,
      );
    }
    const mapped: CanonicalGlucoseReadingV01 = mapMockPayloadToCanonical(
      env.payload as unknown as MockGlucosePayload,
      env,
    );
    return finalize(mapped, env, traceId, options);
  }

  if (env.source === "dexcom") {
    if (!validateDexcomPayload(env.payload)) {
      return failure(
        "PAYLOAD_INVALID",
        formatAjvErrors(validateDexcomPayload.errors),
        traceId,
      );
    }
    const mapped: CanonicalGlucoseReadingV01 = mapDexcomPayloadToCanonical(
      env.payload as unknown as DexcomGlucosePayload,
      env,
    );
    return finalize(mapped, env, traceId, options);
  }

  return failure("ADAPTER_UNKNOWN", `Unsupported source: ${env.source}`, traceId, "source");
}

function finalize(
  mapped: CanonicalGlucoseReadingV01,
  env: IngestionEnvelope,
  traceId: string,
  options?: SubmitOptions,
): PipelineResult<CanonicalGlucoseReadingV01> {
  let normalized: CanonicalGlucoseReadingV01;
  try {
    normalized = normalizeCanonicalReading(mapped, env.received_at);
  } catch (e) {
    const msg: string = e instanceof Error ? e.message : String(e);
    return failure("MAPPING_FAILED", msg, traceId);
  }

  const semantic: StructuredPipelineError | null = applySemanticRules(normalized, traceId);
  if (semantic !== null) {
    return { ok: false, error: semantic };
  }

  if (options?.dedupe !== undefined) {
    const key: string = options.dedupe.makeKey(
      normalized.subject_id,
      normalized.observed_at,
      normalized.provenance.raw_event_id,
    );
    if (!options.dedupe.checkAndRemember(key)) {
      return failure("DUPLICATE_EVENT", "Duplicate ingestion key", traceId);
    }
  }

  if (!validateGlucoseReadingOgis(normalized)) {
    return failure(
      "CANONICAL_SCHEMA_INVALID",
      formatAjvErrors(validateGlucoseReadingOgis.errors),
      traceId,
    );
  }

  return { ok: true, value: normalized };
}
