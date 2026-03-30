/**
 * Wire ingestion envelope (matches `spec/ingestion-envelope.schema.json`).
 * Shared by the collector engine and registry to avoid circular imports.
 */
export type IngestionEnvelope = {
  source: string;
  payload: Record<string, unknown>;
  received_at: string;
  trace_id: string;
  adapter: { id: string; version: string };
};
