import Foundation

/// Manual validation against `spec/pinned/glucose.reading.v0_1.json` (Ajv parity for MVP fields).
/// Returns a human-readable message, or `nil` if valid.
public func ogtValidateGlucoseReadingOgis(_ reading: OGTCanonicalGlucoseReadingV1) -> String? {
    if reading.eventType != "glucose.reading" {
        return "/event_type: must be const glucose.reading"
    }
    if reading.eventVersion != "0.1" {
        return "/event_version: must be const 0.1"
    }
    if reading.subjectId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return "/subject_id: must NOT have fewer than 1 characters"
    }
    if ogtParseEpochMsForValidation(reading.observedAt) == nil {
        return "/observed_at: must match format \"date-time\""
    }
    if reading.value <= 0 {
        return "/value: must be > 0"
    }
    if reading.unit != "mg/dL" && reading.unit != "mmol/L" {
        return "/unit: must be equal to one of the allowed values"
    }
    let msAllowed: Set<String> = ["cgm", "bgm", "manual"]
    if !msAllowed.contains(reading.measurementSource) {
        return "/measurement_source: must be equal to one of the allowed values"
    }
    let deviceTypes: Set<String> = ["cgm", "bgm", "unknown", "phone", "watch", "app", "other"]
    if !deviceTypes.contains(reading.device.type) {
        return "/device/type: must be equal to one of the allowed values"
    }
    if reading.provenance.sourceSystem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return "/provenance/source_system: must NOT have fewer than 1 characters"
    }
    if reading.provenance.rawEventId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return "/provenance/raw_event_id: must NOT have fewer than 1 characters"
    }
    if reading.provenance.adapterVersion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return "/provenance/adapter_version: must NOT have fewer than 1 characters"
    }
    if ogtParseEpochMsForValidation(reading.provenance.ingestedAt) == nil {
        return "/provenance/ingested_at: must match format \"date-time\""
    }
    if let received: String = reading.receivedAt, ogtParseEpochMsForValidation(received) == nil {
        return "/received_at: must match format \"date-time\""
    }
    if let sr: String = reading.sourceRecordedAt, ogtParseEpochMsForValidation(sr) == nil {
        return "/source_recorded_at: must match format \"date-time\""
    }
    if let trend: OGTCanonicalTrend = reading.trend {
        let dirs: Set<String> = ["rising", "falling", "stable", "unknown"]
        if let d: String = trend.direction, !dirs.contains(d) {
            return "/trend/direction: must be equal to one of the allowed values"
        }
    }
    if let q: OGTCanonicalQuality = reading.quality {
        let statuses: Set<String> = ["valid", "questionable", "invalid", "unknown"]
        if let s: String = q.status, !statuses.contains(s) {
            return "/quality/status: must be equal to one of the allowed values"
        }
    }
    return nil
}

private func ogtParseEpochMsForValidation(_ iso: String) -> Int64? {
    OGTRFC3339.epochMs(iso)
}
