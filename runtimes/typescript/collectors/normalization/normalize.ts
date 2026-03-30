import type { CanonicalGlucoseReadingV01, GlucoseUnit } from "../canonical/canonical-glucose-reading.js";

/** OGIS: mmol/L = mg/dL / 18.018 (exact factor). */
export const MGDL_PER_MMOL: number = 18.018;

export type { GlucoseUnit };

/**
 * Parse RFC 3339 / ISO 8601; return UTC ISO string trimmed to milliseconds (sub-ms dropped).
 */
export function normalizeTimestamp(iso: string): string {
  const d: Date = new Date(iso);
  const t: number = d.getTime();
  if (Number.isNaN(t)) {
    throw new Error(`Invalid date-time: ${iso}`);
  }
  return new Date(t).toISOString();
}

/**
 * GAT MVP: normalize glucose to mg/dL per OGIS unit-semantics guidance.
 * Rounds to one decimal for values converted from mmol/L.
 */
export function normalizeGlucoseToMgdl(value: number, unit: GlucoseUnit): { value: number; unit: "mg/dL" } {
  if (unit === "mg/dL") {
    return { value: roundMgdl(value), unit: "mg/dL" };
  }
  const mgdl: number = value * MGDL_PER_MMOL;
  return { value: roundMgdl(mgdl), unit: "mg/dL" };
}

function roundMgdl(n: number): number {
  return Math.round(n * 10) / 10;
}

const MAX_VENDOR_STRING_LEN: number = 256;

export function boundOptionalString(s: string | undefined): string | undefined {
  if (s === undefined) {
    return undefined;
  }
  const t: string = s.trim();
  if (t.length === 0) {
    return undefined;
  }
  if (t.length > MAX_VENDOR_STRING_LEN) {
    return t.slice(0, MAX_VENDOR_STRING_LEN);
  }
  return t;
}

/** Remove keys whose value is null or undefined (shallow). */
export function stripNulls<T extends Record<string, unknown>>(obj: T): T {
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(obj)) {
    if (v !== null && v !== undefined) {
      out[k] = v;
    }
  }
  return out as T;
}

export function normalizeCanonicalReading(
  reading: CanonicalGlucoseReadingV01,
  envelopeReceivedAt: string,
): CanonicalGlucoseReadingV01 {
  const observedAt: string = normalizeTimestamp(reading.observed_at);
  let sourceRecorded: string | undefined = reading.source_recorded_at;
  if (sourceRecorded !== undefined) {
    sourceRecorded = normalizeTimestamp(sourceRecorded);
  }
  const receivedAt: string | undefined =
    reading.received_at !== undefined ? normalizeTimestamp(reading.received_at) : undefined;
  const ingestedAt: string = normalizeTimestamp(reading.provenance.ingested_at);

  const glucose: { value: number; unit: "mg/dL" } = normalizeGlucoseToMgdl(reading.value, reading.unit);

  const deviceManufacturer: string | undefined = boundOptionalString(reading.device.manufacturer);
  const deviceModel: string | undefined = boundOptionalString(reading.device.model);

  const next: CanonicalGlucoseReadingV01 = {
    ...reading,
    observed_at: observedAt,
    value: glucose.value,
    unit: glucose.unit,
    received_at: receivedAt ?? normalizeTimestamp(envelopeReceivedAt),
    provenance: {
      ...reading.provenance,
      ingested_at: ingestedAt,
      source_system: reading.provenance.source_system.trim(),
      raw_event_id: reading.provenance.raw_event_id.trim(),
      adapter_version: reading.provenance.adapter_version.trim(),
    },
    device: {
      type: reading.device.type,
      ...(deviceManufacturer !== undefined ? { manufacturer: deviceManufacturer } : {}),
      ...(deviceModel !== undefined ? { model: deviceModel } : {}),
    },
  };

  if (sourceRecorded !== undefined) {
    next.source_recorded_at = sourceRecorded;
  } else {
    delete next.source_recorded_at;
  }

  return stripNulls(next) as CanonicalGlucoseReadingV01;
}
