import Foundation

// MARK: - Mock → OGIS-shaped canonical (pre-normalize)

/// Maps mock adapter payload to pre-canonical fields.
/// Port of `runtimes/typescript/adapters/mock/map.ts`.
public struct OGTMockIngestAdapter: OGTSourceAdapter, Sendable {
    public static let sourceId: String = "mock"

    public init() {}

    public func mapPayload(_ payload: OGTJSONValue, envelope: OGTIngestionEnvelope) throws -> OGTCanonicalGlucoseReadingV01 {
        try Self.mapPayloadToCanonical(payload, envelope: envelope)
    }

    public static func mapPayloadToCanonical(
        _ payload: OGTJSONValue,
        envelope: OGTIngestionEnvelope
    ) throws -> OGTCanonicalGlucoseReadingV01 {
        let object: [String: OGTJSONValue] = try ogtRequireObject(payload)
        let subjectId: String = try ogtRequireString(object, key: "subject_id")
        let value: Double = try ogtRequireNumber(object, key: "value")
        let unit: String = try ogtRequireString(object, key: "unit")
        let observedAt: String = try ogtRequireString(object, key: "observed_at")

        return OGTCanonicalGlucoseReadingV01(
            eventType: "glucose.reading",
            eventVersion: "0.1",
            subjectId: subjectId,
            observedAt: observedAt,
            sourceRecordedAt: nil,
            receivedAt: nil,
            value: value,
            unit: unit,
            measurementSource: "manual",
            device: OGTCanonicalDevice(
                type: "app",
                manufacturer: "ogt.mock",
                model: envelope.adapter.id
            ),
            provenance: OGTCanonicalProvenance(
                sourceSystem: "ogt.mock",
                rawEventId: "mock:\(subjectId):\(observedAt)",
                adapterVersion: envelope.adapter.version,
                ingestedAt: envelope.receivedAt
            ),
            trend: nil,
            quality: nil
        )
    }
}
