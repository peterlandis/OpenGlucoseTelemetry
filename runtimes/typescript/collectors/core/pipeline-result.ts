export type PipelineIssueCode =
  | "ENVELOPE_INVALID"
  | "PAYLOAD_INVALID"
  | "ADAPTER_UNKNOWN"
  | "MAPPING_FAILED"
  | "SEMANTIC_INVALID"
  | "CANONICAL_SCHEMA_INVALID"
  | "DUPLICATE_EVENT";

export type StructuredPipelineError = {
  code: PipelineIssueCode;
  message: string;
  field?: string;
  trace_id: string;
};

export type PipelineResult<T> =
  | { ok: true; value: T }
  | { ok: false; error: StructuredPipelineError };

export function err(
  code: PipelineIssueCode,
  message: string,
  traceId: string,
  field?: string,
): StructuredPipelineError {
  const e: StructuredPipelineError = { code, message, trace_id: traceId };
  if (field !== undefined) {
    e.field = field;
  }
  return e;
}

export function failure<T>(
  code: PipelineIssueCode,
  message: string,
  traceId: string,
  field?: string,
): PipelineResult<T> {
  return { ok: false, error: err(code, message, traceId, field) };
}
