import Foundation

// MARK: - Envelope (parity with validateEnvelope + schema rules)

public func ogtValidateIngestionEnvelope(_ envelope: OGTIngestionEnvelope) -> String? {
    if envelope.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return "/source: must NOT have fewer than 1 characters"
    }
    if envelope.traceId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return "/trace_id: must NOT have fewer than 1 characters"
    }
    if envelope.adapter.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return "/adapter/id: must NOT have fewer than 1 characters"
    }
    if envelope.adapter.version.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return "/adapter/version: must NOT have fewer than 1 characters"
    }
    if !ogtIsValidOgDateTimeString(envelope.receivedAt) {
        return "/received_at: must match format \"date-time\""
    }
    if case .object = envelope.payload {
        return nil
    }
    return "/payload: must be object"
}

// MARK: - Payloads (strict keys + required fields)

private let healthKitPayloadKeys: Set<String> = [
    "uuid", "value", "unit", "startDate", "endDate", "subject_id",
    "sourceName", "sourceBundleId", "metadata",
]

private let mockPayloadKeys: Set<String> = ["subject_id", "value", "unit", "observed_at"]

private let dexcomPayloadKeys: Set<String> = [
    "event_id", "subject_id", "system_time", "display_time", "value", "unit",
    "trend_arrow", "trend_rate", "trend_rate_unit", "quality_status", "device_model",
]

public func ogtValidateHealthKitPayload(_ payload: OGTJSONValue) throws {
    let object: [String: OGTJSONValue] = try ogtRequireObject(payload)
    try ogtAssertOnlyKeys(object, allowed: healthKitPayloadKeys)
    let uuid: String = try ogtRequireString(object, key: "uuid")
    if uuid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        throw OGTJSONExtractError.wrongType("/uuid: must NOT have fewer than 1 characters")
    }
    _ = try ogtRequireNumber(object, key: "value")
    let unit: String = try ogtRequireString(object, key: "unit")
    if unit != "mg/dL" && unit != "mmol/L" {
        throw OGTJSONExtractError.wrongType("/unit: invalid enum")
    }
    let startDate: String = try ogtRequireString(object, key: "startDate")
    if startDate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        throw OGTJSONExtractError.wrongType("/startDate: empty")
    }
    let endDate: String = try ogtRequireString(object, key: "endDate")
    if endDate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        throw OGTJSONExtractError.wrongType("/endDate: empty")
    }
    let subjectId: String = try ogtRequireString(object, key: "subject_id")
    if subjectId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        throw OGTJSONExtractError.wrongType("/subject_id: empty")
    }
}

public func ogtValidateMockPayload(_ payload: OGTJSONValue) throws {
    let object: [String: OGTJSONValue] = try ogtRequireObject(payload)
    try ogtAssertOnlyKeys(object, allowed: mockPayloadKeys)
    let subjectId: String = try ogtRequireString(object, key: "subject_id")
    if subjectId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        throw OGTJSONExtractError.wrongType("/subject_id: empty")
    }
    _ = try ogtRequireNumber(object, key: "value")
    let unit: String = try ogtRequireString(object, key: "unit")
    if unit != "mg/dL" && unit != "mmol/L" {
        throw OGTJSONExtractError.wrongType("/unit: invalid enum")
    }
    let observedAt: String = try ogtRequireString(object, key: "observed_at")
    if observedAt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        throw OGTJSONExtractError.wrongType("/observed_at: empty")
    }
}

public func ogtValidateDexcomPayload(_ payload: OGTJSONValue) throws {
    let object: [String: OGTJSONValue] = try ogtRequireObject(payload)
    try ogtAssertOnlyKeys(object, allowed: dexcomPayloadKeys)
    let eventId: String = try ogtRequireString(object, key: "event_id")
    if eventId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        throw OGTJSONExtractError.wrongType("/event_id: empty")
    }
    let subjectId: String = try ogtRequireString(object, key: "subject_id")
    if subjectId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        throw OGTJSONExtractError.wrongType("/subject_id: empty")
    }
    let systemTime: String = try ogtRequireString(object, key: "system_time")
    if systemTime.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        throw OGTJSONExtractError.wrongType("/system_time: empty")
    }
    _ = try ogtRequireNumber(object, key: "value")
    let unit: String = try ogtRequireString(object, key: "unit")
    if unit != "mg/dL" && unit != "mmol/L" {
        throw OGTJSONExtractError.wrongType("/unit: invalid enum")
    }
    if let qs: String = try ogtOptionalString(object, key: "quality_status") {
        let allowed: Set<String> = ["valid", "questionable", "invalid", "unknown"]
        if !allowed.contains(qs) {
            throw OGTJSONExtractError.wrongType("/quality_status: invalid enum")
        }
    }
}
