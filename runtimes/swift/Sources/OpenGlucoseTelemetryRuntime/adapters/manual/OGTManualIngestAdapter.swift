import Foundation

// MARK: - Manual (fixture JSON) → OGIS-shaped canonical (pre-normalize)

/// Maps manual-entry payloads to pre-normalization canonical reading.
///
/// Payload shape matches mock (`subject_id`, `value`, `unit`, `observed_at`), but routes under a stable `manual` source id.
public struct OGTManualIngestAdapter: OGTSourceAdapter, Sendable {
    public static let sourceId: String = "manual"

    public init() {}

    public func mapPayload(_ payload: OGTJSONValue, envelope: OGTIngestionEnvelope) throws -> OGTCanonicalGlucoseReadingV1 {
        try Self.mapPayloadToCanonical(payload, envelope: envelope)
    }

    public static func mapPayloadToCanonical(
        _ payload: OGTJSONValue,
        envelope: OGTIngestionEnvelope
    ) throws -> OGTCanonicalGlucoseReadingV1 {
        let object: [String: OGTJSONValue] = try ogtRequireObject(payload)
        let subjectId: String = try ogtRequireString(object, key: "subject_id")
        let value: Double = try ogtRequireNumber(object, key: "value")
        let unit: String = try ogtRequireString(object, key: "unit")
        let observedAt: String = try ogtRequireString(object, key: "observed_at")

        return OGTCanonicalGlucoseReadingV1(
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
                manufacturer: envelope.adapter.id,
                model: nil
            ),
            provenance: OGTCanonicalProvenance(
                sourceSystem: "manual",
                rawEventId: "manual:\(subjectId):\(observedAt)",
                adapterVersion: envelope.adapter.version,
                ingestedAt: envelope.receivedAt
            ),
            trend: nil,
            quality: nil
        )
    }
}

// MARK: - Pipeline registration

public extension OGTManualIngestAdapter {
    /// Pluggable registration for [`OGTDefaultAdapterRegistry`](../../collectors/OGTAdapterRegistry.swift).
    static let ogtRegistration: OGTAdapterRegistration = OGTAdapterRegistration(
        sourceId: OGTManualIngestAdapter.sourceId,
        validatePayload: { (payload: OGTJSONValue) throws -> Void in
            // Manual payload is identical to mock payload shape.
            try ogtValidateMockPayload(payload)
        },
        mapPayload: { (payload: OGTJSONValue, envelope: OGTIngestionEnvelope) throws -> OGTCanonicalGlucoseReadingV1 in
            try OGTManualIngestAdapter().mapPayload(payload, envelope: envelope)
        }
    )
}

