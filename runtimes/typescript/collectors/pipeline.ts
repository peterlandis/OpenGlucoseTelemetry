/**
 * Public entry for the ingestion pipeline. Implementation: [`core/collector-engine.ts`](./core/collector-engine.ts).
 */
export { submit } from "./core/collector-engine.js";
export type { SubmitOptions } from "./core/submit-options.js";
export type { IngestionEnvelope } from "./ingestion/ingestion-types.js";
export type {
  PipelineResult,
  StructuredPipelineError,
  PipelineIssueCode,
} from "./core/pipeline-result.js";
export type { CanonicalGlucoseReadingV01 } from "./canonical/canonical-glucose-reading.js";
export { err, failure } from "./core/pipeline-result.js";
export { DedupeTracker } from "./normalization/dedupe.js";
