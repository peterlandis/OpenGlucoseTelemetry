import Foundation

// MARK: - Adapter contract

/// One adapter per `source` id (e.g. `healthkit`, `dexcom`, `mock`).
/// Implementations live under `adapters/<source>/` and mirror `runtimes/typescript/adapters/<source>/map.ts`.
public protocol OGTSourceAdapter: Sendable {
    static var sourceId: String { get }

    /// Map vendor `payload` JSON into OGIS-shaped `glucose.reading` fields (before collector normalization).
    func mapPayload(_ payload: OGTJSONValue, envelope: OGTIngestionEnvelope) throws -> OGTCanonicalGlucoseReadingV01
}
