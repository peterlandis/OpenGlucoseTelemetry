import type { CanonicalGlucoseReadingV01 } from "../../collectors/normalize.js";

export type MockGlucosePayload = {
  subject_id: string;
  value: number;
  unit: "mg/dL" | "mmol/L";
  observed_at: string;
};

export function mapMockPayloadToCanonical(
  payload: MockGlucosePayload,
  envelope: { received_at: string; adapter: { id: string; version: string } },
): CanonicalGlucoseReadingV01 {
  return {
    event_type: "glucose.reading",
    event_version: "0.1",
    subject_id: payload.subject_id,
    observed_at: payload.observed_at,
    value: payload.value,
    unit: payload.unit,
    measurement_source: "manual",
    device: {
      type: "app",
      manufacturer: "ogt.mock",
      model: envelope.adapter.id,
    },
    provenance: {
      source_system: "ogt.mock",
      raw_event_id: `mock:${payload.subject_id}:${payload.observed_at}`,
      adapter_version: envelope.adapter.version,
      ingested_at: envelope.received_at,
    },
  };
}
