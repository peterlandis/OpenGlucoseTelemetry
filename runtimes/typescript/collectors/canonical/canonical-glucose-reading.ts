/** OGIS-shaped canonical reading (pre- and post-normalize) for `glucose.reading` v0.1. */
export type GlucoseUnit = "mg/dL" | "mmol/L";

export type CanonicalGlucoseReadingV01 = {
  event_type: "glucose.reading";
  event_version: "0.1";
  subject_id: string;
  observed_at: string;
  source_recorded_at?: string;
  received_at?: string;
  value: number;
  unit: GlucoseUnit;
  measurement_source: "cgm" | "bgm" | "manual";
  device: {
    type: "cgm" | "bgm" | "unknown" | "phone" | "watch" | "app" | "other";
    manufacturer?: string;
    model?: string;
  };
  provenance: {
    source_system: string;
    raw_event_id: string;
    adapter_version: string;
    ingested_at: string;
  };
  trend?: {
    direction?: "rising" | "falling" | "stable" | "unknown";
    rate?: number;
    rate_unit?: string;
  };
  quality?: {
    status?: "valid" | "questionable" | "invalid" | "unknown";
  };
};
