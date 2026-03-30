import Foundation

// MARK: - Adapter registry

/// Dispatches `source` strings to the adapter implementation under `adapters/`.
public protocol OGTAdapterRegistry: Sendable {
    func mapPayload(
        for source: String,
        payload: OGTJSONValue,
        envelope: OGTIngestionEnvelope
    ) throws -> OGTCanonicalGlucoseReadingV01
}

/// Default registry matching the TypeScript MVP sources: `healthkit`, `dexcom`, `mock`.
public struct OGTDefaultAdapterRegistry: OGTAdapterRegistry, Sendable {
    public init() {}

    public func mapPayload(
        for source: String,
        payload: OGTJSONValue,
        envelope: OGTIngestionEnvelope
    ) throws -> OGTCanonicalGlucoseReadingV01 {
        switch source {
        case OGTHealthKitIngestAdapter.sourceId:
            return try OGTHealthKitIngestAdapter().mapPayload(payload, envelope: envelope)
        case OGTDexcomIngestAdapter.sourceId:
            return try OGTDexcomIngestAdapter().mapPayload(payload, envelope: envelope)
        case OGTMockIngestAdapter.sourceId:
            return try OGTMockIngestAdapter().mapPayload(payload, envelope: envelope)
        default:
            throw OGTPipelineError.unknownSource(source)
        }
    }
}
