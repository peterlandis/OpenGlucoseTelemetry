import Foundation

// MARK: - Pluggable adapter registration

/// Bundles **payload validation** and **map** for one `source` id. Register in **`OGTAdapterCatalog.builtinRegistrations`** when adding `adapters/<source>/`; **do not** edit **`OGTCollectorEngine.run`**.
public struct OGTAdapterRegistration: Sendable {
    public let sourceId: String

    private let validate: @Sendable (OGTJSONValue) throws -> Void
    private let map: @Sendable (OGTJSONValue, OGTIngestionEnvelope) throws -> OGTCanonicalGlucoseReadingV1

    public init(
        sourceId: String,
        validatePayload: @escaping @Sendable (OGTJSONValue) throws -> Void,
        mapPayload: @escaping @Sendable (OGTJSONValue, OGTIngestionEnvelope) throws -> OGTCanonicalGlucoseReadingV1
    ) {
        self.sourceId = sourceId
        self.validate = validatePayload
        self.map = mapPayload
    }

    public func validatePayload(_ payload: OGTJSONValue) throws {
        try validate(payload)
    }

    public func mapPayload(_ payload: OGTJSONValue, envelope: OGTIngestionEnvelope) throws -> OGTCanonicalGlucoseReadingV1 {
        try map(payload, envelope)
    }
}
