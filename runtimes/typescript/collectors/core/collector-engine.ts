import type { PipelineResult, StructuredPipelineError } from "./pipeline-result.js";
import { failure } from "./pipeline-result.js";
import { formatAjvErrors, validateEnvelope, validateGlucoseReadingOgis } from "../validation/schema-validators.js";
import type { CanonicalGlucoseReadingV01 } from "../canonical/canonical-glucose-reading.js";
import { normalizeCanonicalReading } from "../normalization/normalize.js";
import { applySemanticRules } from "../validation/semantic.js";
import type { IngestionEnvelope } from "../ingestion/ingestion-types.js";
import { builtinIngestPlugins } from "../registry/ingest-plugins.js";
import type { SubmitOptions } from "./submit-options.js";

/**
 * End-to-end MVP pipeline: envelope → plugin (validate + map) → normalize → semantic rules → OGIS JSON Schema.
 * Per-source logic lives in `registry/ingest-plugins.ts`, not in `if` chains here.
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

  const plugin = builtinIngestPlugins[env.source];
  if (plugin === undefined) {
    return failure("ADAPTER_UNKNOWN", `Unsupported source: ${env.source}`, traceId, "source");
  }

  if (!plugin.validatePayload(env.payload)) {
    return failure("PAYLOAD_INVALID", plugin.payloadValidationErrors(), traceId);
  }

  const mapped: CanonicalGlucoseReadingV01 = plugin.mapToCanonical(env.payload, env);
  return finalize(mapped, env, traceId, options);
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

export type { SubmitOptions } from "./submit-options.js";
export { DedupeTracker } from "../normalization/dedupe.js";
