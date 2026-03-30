import type { CanonicalGlucoseReadingV01 } from "../../collectors/canonical/canonical-glucose-reading.js";

export type HealthKitGlucosePayload = {
  uuid: string;
  value: number;
  unit: "mg/dL" | "mmol/L";
  startDate: string;
  endDate: string;
  subject_id: string;
  sourceName?: string;
  sourceBundleId?: string;
  metadata?: Record<string, unknown>;
};

function metadataBoolean(meta: Record<string, unknown> | undefined, key: string): boolean | undefined {
  if (meta === undefined) {
    return undefined;
  }
  const v: unknown = meta[key];
  if (typeof v === "boolean") {
    return v;
  }
  if (typeof v === "string") {
    if (v === "true" || v === "1") {
      return true;
    }
    if (v === "false" || v === "0") {
      return false;
    }
  }
  return undefined;
}

function inferMeasurementSource(payload: HealthKitGlucosePayload): "cgm" | "bgm" | "manual" {
  const userEntered: boolean | undefined = metadataBoolean(payload.metadata, "HKWasUserEntered");
  if (userEntered === true) {
    return "manual";
  }
  const bundle: string = (payload.sourceBundleId ?? "").toLowerCase();
  if (
    bundle.includes("dexcom") ||
    bundle.includes("libre") ||
    bundle.includes("freestyle") ||
    bundle.includes("medtronic")
  ) {
    return "cgm";
  }
  return "bgm";
}

function inferDeviceType(measurement: "cgm" | "bgm" | "manual"): CanonicalGlucoseReadingV01["device"]["type"] {
  if (measurement === "cgm") {
    return "cgm";
  }
  if (measurement === "bgm") {
    return "bgm";
  }
  return "app";
}

/**
 * Map HealthKit-shaped JSON payload to pre-normalization canonical reading.
 */
export function mapHealthKitPayloadToCanonical(
  payload: HealthKitGlucosePayload,
  envelope: { received_at: string; adapter: { id: string; version: string } },
): CanonicalGlucoseReadingV01 {
  const measurement: "cgm" | "bgm" | "manual" = inferMeasurementSource(payload);
  const deviceType: CanonicalGlucoseReadingV01["device"]["type"] = inferDeviceType(measurement);

  const manufacturer: string | undefined =
    payload.sourceName !== undefined && payload.sourceName.trim().length > 0
      ? payload.sourceName.trim()
      : undefined;

  const reading: CanonicalGlucoseReadingV01 = {
    event_type: "glucose.reading",
    event_version: "0.1",
    subject_id: payload.subject_id,
    observed_at: payload.startDate,
    value: payload.value,
    unit: payload.unit,
    measurement_source: measurement,
    device: {
      type: deviceType,
      ...(manufacturer !== undefined ? { manufacturer } : {}),
      ...(payload.sourceBundleId !== undefined && payload.sourceBundleId.length > 0
        ? { model: payload.sourceBundleId }
        : {}),
    },
    provenance: {
      source_system: "com.apple.health",
      raw_event_id: payload.uuid,
      adapter_version: envelope.adapter.version,
      ingested_at: envelope.received_at,
    },
  };

  if (payload.endDate !== payload.startDate) {
    reading.source_recorded_at = payload.endDate;
  }

  return reading;
}
