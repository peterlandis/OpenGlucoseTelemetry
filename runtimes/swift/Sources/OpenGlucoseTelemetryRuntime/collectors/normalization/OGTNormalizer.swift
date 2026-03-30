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
    let trimmed: String = iso.trimmingCharacters(in: .whitespacesAndNewlines)
    let formatterFractional: ISO8601DateFormatter = ISO8601DateFormatter()
    formatterFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    formatterFractional.timeZone = TimeZone(secondsFromGMT: 0)
    if let date: Date = formatterFractional.date(from: trimmed) {
        return ogtIso8601MillisUTC(date)
    }
    let formatterBasic: ISO8601DateFormatter = ISO8601DateFormatter()
    formatterBasic.formatOptions = [.withInternetDateTime]
    formatterBasic.timeZone = TimeZone(secondsFromGMT: 0)
    guard let date2: Date = formatterBasic.date(from: trimmed) else {
        throw OGTNormalizerError.invalidDateTime(iso)
    }
    return ogtIso8601MillisUTC(date2)
}

private func ogtIso8601MillisUTC(_ date: Date) -> String {
    let ms: Int64 = Int64((date.timeIntervalSince1970 * 1000.0).rounded(.down))
    let rounded: Date = Date(timeIntervalSince1970: Double(ms) / 1000.0)
    let out: ISO8601DateFormatter = ISO8601DateFormatter()
    out.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    out.timeZone = TimeZone(secondsFromGMT: 0)
    return out.string(from: rounded)
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
    let f1: ISO8601DateFormatter = ISO8601DateFormatter()
    f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    f1.timeZone = TimeZone(secondsFromGMT: 0)
    if f1.date(from: iso) != nil {
        return true
    }
    let f2: ISO8601DateFormatter = ISO8601DateFormatter()
    f2.formatOptions = [.withInternetDateTime]
    f2.timeZone = TimeZone(secondsFromGMT: 0)
    return f2.date(from: iso) != nil
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
