import Foundation

// MARK: - Adapter metadata (nested in envelope JSON)

/// The `adapter` object on the wire: which adapter produced this submission and its version.
/// Matches `spec/ingestion-envelope.schema.json` → `properties.adapter`.
public struct OGTAdapterWireMetadata: Codable, Sendable {
    public let id: String
    public let version: String

    public init(id: String, version: String) {
        self.id = id
        self.version = version
    }
}

// MARK: - Ingestion envelope (wire)

/// OGT **ingestion envelope** — the wrapper around a vendor `payload` that the collector ingests.
///
/// This is the JSON shape defined by **`spec/ingestion-envelope.schema.json`** (OGT MVP v0.1) and mirrored in TypeScript as `IngestionEnvelope` in `runtimes/typescript/collectors/ingestion/ingestion-types.ts` (re-exported from `pipeline.ts`).
///
/// **Semantics (schema):**
/// - **`source`** — Stable channel id (e.g. `healthkit`, `dexcom`, `mock`); drives adapter routing.
/// - **`payload`** — Source-specific object; validated per `source` by the collector (not by the envelope schema alone).
/// - **`received_at`** — When OGT received the submission (RFC 3339).
/// - **`trace_id`** — Correlation id for logs and tests.
/// - **`adapter`** — Producer identity (`id`, `version`) for provenance.
public struct OGTIngestionEnvelope: Codable, Sendable {
    public let source: String
    public let payload: OGTJSONValue
    public let receivedAt: String
    public let traceId: String
    public let adapter: OGTAdapterWireMetadata

    public init(
        source: String,
        payload: OGTJSONValue,
        receivedAt: String,
        traceId: String,
        adapter: OGTAdapterWireMetadata
    ) {
        self.source = source
        self.payload = payload
        self.receivedAt = receivedAt
        self.traceId = traceId
        self.adapter = adapter
    }

    enum CodingKeys: String, CodingKey {
        case source
        case payload
        case receivedAt = "received_at"
        case traceId = "trace_id"
        case adapter
    }
}

// MARK: - JSON helpers

public extension OGTIngestionEnvelope {
    /// Decodes an envelope from UTF-8 JSON `Data` using default `JSONDecoder` (snake_case keys via `CodingKeys`).
    static func decode(from data: Data) throws -> OGTIngestionEnvelope {
        let decoder: JSONDecoder = JSONDecoder()
        return try decoder.decode(OGTIngestionEnvelope.self, from: data)
    }

    /// Encodes this envelope to JSON `Data` with stable key formatting from `CodingKeys`.
    func encodeToJSONData() throws -> Data {
        let encoder: JSONEncoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(self)
    }
}
