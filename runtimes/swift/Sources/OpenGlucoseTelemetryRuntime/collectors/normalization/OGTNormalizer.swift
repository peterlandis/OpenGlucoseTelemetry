import Foundation

// MARK: - Constants (parity with normalize.ts)

/// OGIS: mmol/L = mg/dL / 18.018 (exact factor).
public let OGT_MGDL_PER_MMOL: Double = 18.018

private let maxVendorStringLength: Int = 256

// MARK: - Errors

public enum OGTNormalizerError: Error, Sendable, Equatable {
    case invalidDateTime(String)
}

extension OGTNormalizerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidDateTime(let iso):
            return "Invalid date-time: \(iso)"
        }
    }
}

// MARK: - Timestamp (RFC 3339 → UTC ISO with ms, sub-ms dropped)

/// Parses RFC 3339 / ISO 8601; returns UTC ISO string trimmed to milliseconds (parity with `normalizeTimestamp` in TS).
public func ogtNormalizeTimestamp(iso: String) throws -> String {
    try OGTRFC3339.normalizeToMillisUTC(iso)
}

private func ogtIso8601MillisUTC(_ date: Date) -> String {
    OGTRFC3339.encodeMillisUTC(date)
}

// MARK: - Glucose unit normalization

/// GAT MVP: normalize glucose to mg/dL per OGIS unit-semantics; rounds to one decimal when converting from mmol/L.
public func ogtNormalizeGlucoseToMgdl(value: Double, unit: String) -> (value: Double, unit: String) {
    if unit == "mg/dL" {
        return (ogtRoundMgdl(value), "mg/dL")
    }
    if unit == "mmol/L" {
        let mgdl: Double = value * OGT_MGDL_PER_MMOL
        return (ogtRoundMgdl(mgdl), "mg/dL")
    }
    return (ogtRoundMgdl(value), "mg/dL")
}

private func ogtRoundMgdl(_ n: Double) -> Double {
    (n * 10.0).rounded() / 10.0
}

// MARK: - Strings

public func ogtBoundOptionalString(_ s: String?) -> String? {
    guard let s: String = s else {
        return nil
    }
    let t: String = s.trimmingCharacters(in: .whitespacesAndNewlines)
    if t.isEmpty {
        return nil
    }
    if t.count > maxVendorStringLength {
        let idx: String.Index = t.index(t.startIndex, offsetBy: maxVendorStringLength)
        return String(t[..<idx])
    }
    return t
}

// MARK: - Canonical reading normalization

/// Whether `iso` parses as RFC 3339 / ISO 8601 (used for envelope / schema checks).
public func ogtIsValidOgDateTimeString(_ iso: String) -> Bool {
    OGTRFC3339.decode(iso) != nil
}

public func ogtNormalizeCanonicalReading(
    reading: OGTCanonicalGlucoseReadingV1,
    envelopeReceivedAt: String
) throws -> OGTCanonicalGlucoseReadingV1 {
    let observedAt: String = try ogtNormalizeTimestamp(iso: reading.observedAt)
    var sourceRecorded: String? = reading.sourceRecordedAt
    if let sr: String = sourceRecorded {
        sourceRecorded = try ogtNormalizeTimestamp(iso: sr)
    }
    let receivedAtNormalized: String? = try reading.receivedAt.map { try ogtNormalizeTimestamp(iso: $0) }
    let ingestedAt: String = try ogtNormalizeTimestamp(iso: reading.provenance.ingestedAt)
    let glucose: (value: Double, unit: String) = ogtNormalizeGlucoseToMgdl(value: reading.value, unit: reading.unit)

    let deviceManufacturer: String? = ogtBoundOptionalString(reading.device.manufacturer)
    let deviceModel: String? = ogtBoundOptionalString(reading.device.model)

    let receivedFinal: String
    if let r: String = receivedAtNormalized {
        receivedFinal = r
    } else {
        receivedFinal = try ogtNormalizeTimestamp(iso: envelopeReceivedAt)
    }

    var next: OGTCanonicalGlucoseReadingV1 = reading
    next.observedAt = observedAt
    next.value = glucose.value
    next.unit = glucose.unit
    next.receivedAt = receivedFinal
    next.sourceRecordedAt = sourceRecorded
    next.provenance = OGTCanonicalProvenance(
        sourceSystem: reading.provenance.sourceSystem.trimmingCharacters(in: .whitespacesAndNewlines),
        rawEventId: reading.provenance.rawEventId.trimmingCharacters(in: .whitespacesAndNewlines),
        adapterVersion: reading.provenance.adapterVersion.trimmingCharacters(in: .whitespacesAndNewlines),
        ingestedAt: ingestedAt
    )
    next.device = OGTCanonicalDevice(
        type: reading.device.type,
        manufacturer: deviceManufacturer,
        model: deviceModel
    )
    return next
}
