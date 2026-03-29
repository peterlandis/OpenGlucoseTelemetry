import type { CanonicalGlucoseReadingV01 } from "../../collectors/normalize.js";

export type DexcomGlucosePayload = {
  event_id: string;
  subject_id: string;
  system_time: string;
  display_time?: string;
  value: number;
  unit: "mg/dL" | "mmol/L";
  trend_arrow?: string;
  trend_rate?: number;
  trend_rate_unit?: string;
  quality_status?: "valid" | "questionable" | "invalid" | "unknown";
  device_model?: string;
};

/**
 * Map Dexcom-style trendArrow / trend field strings to OGIS trend.direction.
 * Typical vendor tokens include flat, none, singleUp, doubleUp, fortyFiveUp, fortyFiveDown, singleDown, doubleDown, notComputable.
 */
export function mapDexcomTrendArrowToDirection(arrow: string | undefined): "rising" | "falling" | "stable" | "unknown" {
  if (arrow === undefined) {
    return "unknown";
  }
  const a: string = arrow.trim().toLowerCase();
  if (a.length === 0) {
    return "unknown";
  }
  if (a === "notcomputable" || a === "not_computable" || a === "rateoutofrange") {
    return "unknown";
  }
  if (a === "doubleup" || a === "singleup" || a === "fortyfiveup") {
    return "rising";
  }
  if (a === "doubledown" || a === "singledown" || a === "fortyfivedown") {
    return "falling";
  }
  if (a === "flat" || a === "none") {
    return "stable";
  }
  return "unknown";
}

/**
 * Map Dexcom-shaped JSON payload to pre-normalization canonical reading.
 */
export function mapDexcomPayloadToCanonical(
  payload: DexcomGlucosePayload,
  envelope: { received_at: string; adapter: { id: string; version: string } },
): CanonicalGlucoseReadingV01 {
  const model: string | undefined =
    payload.device_model !== undefined && payload.device_model.trim().length > 0
      ? payload.device_model.trim()
      : undefined;

  const direction: "rising" | "falling" | "stable" | "unknown" = mapDexcomTrendArrowToDirection(payload.trend_arrow);

  const reading: CanonicalGlucoseReadingV01 = {
    event_type: "glucose.reading",
    event_version: "0.1",
    subject_id: payload.subject_id,
    observed_at: payload.system_time,
    value: payload.value,
    unit: payload.unit,
    measurement_source: "cgm",
    device: {
      type: "cgm",
      manufacturer: "Dexcom",
      ...(model !== undefined ? { model } : {}),
    },
    provenance: {
      source_system: "dexcom",
      raw_event_id: payload.event_id,
      adapter_version: envelope.adapter.version,
      ingested_at: envelope.received_at,
    },
  };

  if (payload.display_time !== undefined && payload.display_time.trim().length > 0) {
    const display: string = payload.display_time.trim();
    const system: string = payload.system_time.trim();
    if (display !== system) {
      reading.source_recorded_at = display;
    }
  }

  const hasTrend: boolean =
    payload.trend_arrow !== undefined ||
    payload.trend_rate !== undefined ||
    payload.trend_rate_unit !== undefined;
  if (hasTrend) {
    reading.trend = {
      direction,
      ...(payload.trend_rate !== undefined ? { rate: payload.trend_rate } : {}),
      ...(payload.trend_rate_unit !== undefined && payload.trend_rate_unit.trim().length > 0
        ? { rate_unit: payload.trend_rate_unit.trim() }
        : {}),
    };
  }

  if (payload.quality_status !== undefined) {
    reading.quality = { status: payload.quality_status };
  }

  return reading;
}
