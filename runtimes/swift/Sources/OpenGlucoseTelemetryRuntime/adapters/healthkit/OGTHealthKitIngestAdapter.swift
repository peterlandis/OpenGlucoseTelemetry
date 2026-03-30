import Foundation

// MARK: - HealthKit (fixture JSON) → OGIS-shaped canonical (pre-normalize)

/// Maps serializable HealthKit-shaped payload to pre-normalization canonical reading.
/// Port of `runtimes/typescript/adapters/healthkit/map.ts`.
public struct OGTHealthKitIngestAdapter: OGTSourceAdapter, Sendable {
    public static let sourceId: String = "healthkit"

    public init() {}

    public func mapPayload(_ payload: OGTJSONValue, envelope: OGTIngestionEnvelope) throws -> OGTCanonicalGlucoseReadingV01 {
        try Self.mapPayloadToCanonical(payload, envelope: envelope)
    }

    public static func mapPayloadToCanonical(
        _ payload: OGTJSONValue,
        envelope: OGTIngestionEnvelope
    ) throws -> OGTCanonicalGlucoseReadingV01 {
        let object: [String: OGTJSONValue] = try ogtRequireObject(payload)
        let uuid: String = try ogtRequireString(object, key: "uuid")
        let value: Double = try ogtRequireNumber(object, key: "value")
        let unit: String = try ogtRequireString(object, key: "unit")
        let startDate: String = try ogtRequireString(object, key: "startDate")
        let endDate: String = try ogtRequireString(object, key: "endDate")
        let subjectId: String = try ogtRequireString(object, key: "subject_id")
        let sourceName: String? = try ogtOptionalString(object, key: "sourceName")
        let sourceBundleId: String? = try ogtOptionalString(object, key: "sourceBundleId")
        let metadata: [String: OGTJSONValue]? = try ogtOptionalObject(object, key: "metadata")

        let measurement: String = inferMeasurementSource(
            sourceBundleId: sourceBundleId,
            metadata: metadata
        )
        let deviceType: String = inferDeviceType(measurement: measurement)

        let manufacturer: String? = {
            guard let name: String = sourceName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
                return nil
            }
            return name
        }()

        var reading: OGTCanonicalGlucoseReadingV01 = OGTCanonicalGlucoseReadingV01(
            eventType: "glucose.reading",
            eventVersion: "0.1",
            subjectId: subjectId,
            observedAt: startDate,
            sourceRecordedAt: nil,
            receivedAt: nil,
            value: value,
            unit: unit,
            measurementSource: measurement,
            device: OGTCanonicalDevice(
                type: deviceType,
                manufacturer: manufacturer,
                model: (sourceBundleId?.isEmpty == false) ? sourceBundleId : nil
            ),
            provenance: OGTCanonicalProvenance(
                sourceSystem: "com.apple.health",
                rawEventId: uuid,
                adapterVersion: envelope.adapter.version,
                ingestedAt: envelope.receivedAt
            ),
            trend: nil,
            quality: nil
        )

        if endDate != startDate {
            reading.sourceRecordedAt = endDate
        }

        return reading
    }

    private static func metadataBoolean(meta: [String: OGTJSONValue]?, key: String) -> Bool? {
        guard let meta: [String: OGTJSONValue] = meta else {
            return nil
        }
        guard let v: OGTJSONValue = meta[key] else {
            return nil
        }
        if case .bool(let b) = v {
            return b
        }
        if case .string(let s) = v {
            if s == "true" || s == "1" {
                return true
            }
            if s == "false" || s == "0" {
                return false
            }
        }
        return nil
    }

    private static func inferMeasurementSource(
        sourceBundleId: String?,
        metadata: [String: OGTJSONValue]?
    ) -> String {
        if metadataBoolean(meta: metadata, key: "HKWasUserEntered") == true {
            return "manual"
        }
        let bundle: String = (sourceBundleId ?? "").lowercased()
        if bundle.contains("dexcom") || bundle.contains("libre") || bundle.contains("freestyle") || bundle.contains("medtronic") {
            return "cgm"
        }
        return "bgm"
    }

    private static func inferDeviceType(measurement: String) -> String {
        if measurement == "cgm" {
            return "cgm"
        }
        if measurement == "bgm" {
            return "bgm"
        }
        return "app"
    }
}
