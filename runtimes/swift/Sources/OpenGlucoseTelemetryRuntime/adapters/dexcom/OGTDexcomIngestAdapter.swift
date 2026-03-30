import Foundation

// MARK: - Dexcom (fixture JSON) → OGIS-shaped canonical (pre-normalize)

/// Maps serializable Dexcom EGV-style payload to pre-canonical fields.
/// Port of `runtimes/typescript/adapters/dexcom/map.ts`.
public struct OGTDexcomIngestAdapter: OGTSourceAdapter, Sendable {
    public static let sourceId: String = "dexcom"

    public init() {}

    public func mapPayload(_ payload: OGTJSONValue, envelope: OGTIngestionEnvelope) throws -> OGTCanonicalGlucoseReadingV1 {
        try Self.mapPayloadToCanonical(payload, envelope: envelope)
    }

    /// Map Dexcom-style trendArrow strings to OGIS `trend.direction`.
    public static func mapDexcomTrendArrowToDirection(arrow: String?) -> String {
        guard let raw: String = arrow?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return "unknown"
        }
        let a: String = raw.lowercased()
        if a == "notcomputable" || a == "not_computable" || a == "rateoutofrange" {
            return "unknown"
        }
        if a == "doubleup" || a == "singleup" || a == "fortyfiveup" {
            return "rising"
        }
        if a == "doubledown" || a == "singledown" || a == "fortyfivedown" {
            return "falling"
        }
        if a == "flat" || a == "none" {
            return "stable"
        }
        return "unknown"
    }

    public static func mapPayloadToCanonical(
        _ payload: OGTJSONValue,
        envelope: OGTIngestionEnvelope
    ) throws -> OGTCanonicalGlucoseReadingV1 {
        let object: [String: OGTJSONValue] = try ogtRequireObject(payload)
        let eventId: String = try ogtRequireString(object, key: "event_id")
        let subjectId: String = try ogtRequireString(object, key: "subject_id")
        let systemTime: String = try ogtRequireString(object, key: "system_time")
        let value: Double = try ogtRequireNumber(object, key: "value")
        let unit: String = try ogtRequireString(object, key: "unit")
        let displayTime: String? = try ogtOptionalString(object, key: "display_time")
        let trendArrow: String? = try ogtOptionalString(object, key: "trend_arrow")
        let trendRate: Double? = try ogtOptionalNumber(object, key: "trend_rate")
        let trendRateUnit: String? = try ogtOptionalString(object, key: "trend_rate_unit")
        let qualityStatus: String? = try ogtOptionalString(object, key: "quality_status")
        let deviceModel: String? = try ogtOptionalString(object, key: "device_model")

        let modelTrimmed: String? = {
            guard let m: String = deviceModel?.trimmingCharacters(in: .whitespacesAndNewlines), !m.isEmpty else {
                return nil
            }
            return m
        }()

        let direction: String = mapDexcomTrendArrowToDirection(arrow: trendArrow)

        var reading: OGTCanonicalGlucoseReadingV1 = OGTCanonicalGlucoseReadingV1(
            eventType: "glucose.reading",
            eventVersion: "0.1",
            subjectId: subjectId,
            observedAt: systemTime,
            sourceRecordedAt: nil,
            receivedAt: nil,
            value: value,
            unit: unit,
            measurementSource: "cgm",
            device: OGTCanonicalDevice(
                type: "cgm",
                manufacturer: "Dexcom",
                model: modelTrimmed
            ),
            provenance: OGTCanonicalProvenance(
                sourceSystem: "dexcom",
                rawEventId: eventId,
                adapterVersion: envelope.adapter.version,
                ingestedAt: envelope.receivedAt
            ),
            trend: nil,
            quality: nil
        )

        if let display: String = displayTime?.trimmingCharacters(in: .whitespacesAndNewlines), !display.isEmpty {
            let system: String = systemTime.trimmingCharacters(in: .whitespacesAndNewlines)
            if display != system {
                reading.sourceRecordedAt = display
            }
        }

        let hasTrend: Bool =
            trendArrow != nil || trendRate != nil
            || (trendRateUnit?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        if hasTrend {
            let rateUnitTrimmed: String? = {
                guard let u: String = trendRateUnit?.trimmingCharacters(in: .whitespacesAndNewlines), !u.isEmpty else {
                    return nil
                }
                return u
            }()
            reading.trend = OGTCanonicalTrend(
                direction: direction,
                rate: trendRate,
                rateUnit: rateUnitTrimmed
            )
        }

        if let qs: String = qualityStatus {
            reading.quality = OGTCanonicalQuality(status: qs)
        }

        return reading
    }
}

// MARK: - Pipeline registration

public extension OGTDexcomIngestAdapter {
    /// Pluggable registration for [`OGTDefaultAdapterRegistry`](../../collectors/OGTAdapterRegistry.swift).
    static let ogtRegistration: OGTAdapterRegistration = OGTAdapterRegistration(
        sourceId: OGTDexcomIngestAdapter.sourceId,
        validatePayload: { (payload: OGTJSONValue) throws -> Void in
            try ogtValidateDexcomPayload(payload)
        },
        mapPayload: { (payload: OGTJSONValue, envelope: OGTIngestionEnvelope) throws -> OGTCanonicalGlucoseReadingV1 in
            try OGTDexcomIngestAdapter().mapPayload(payload, envelope: envelope)
        }
    )
}
