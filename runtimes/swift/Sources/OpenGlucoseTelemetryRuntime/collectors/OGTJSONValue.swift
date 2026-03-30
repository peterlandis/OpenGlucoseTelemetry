import Foundation

// MARK: - Dynamic JSON (ingestion payload)

/// Dynamic JSON value for ingestion `payload` objects until strongly typed per-adapter structs exist.
/// Mirrors `Record<string, unknown>` usage in the TypeScript adapters.
public enum OGTJSONValue: Equatable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: OGTJSONValue])
    case array([OGTJSONValue])
    case null
}

extension OGTJSONValue: Codable {
    public init(from decoder: Decoder) throws {
        let container: SingleValueDecodingContainer = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
            return
        }
        if let boolValue: Bool = try? container.decode(Bool.self) {
            self = .bool(boolValue)
            return
        }
        if let intValue: Int = try? container.decode(Int.self) {
            self = .number(Double(intValue))
            return
        }
        if let doubleValue: Double = try? container.decode(Double.self) {
            self = .number(doubleValue)
            return
        }
        if let stringValue: String = try? container.decode(String.self) {
            self = .string(stringValue)
            return
        }
        if let arrayValue: [OGTJSONValue] = try? container.decode([OGTJSONValue].self) {
            self = .array(arrayValue)
            return
        }
        if let objectValue: [String: OGTJSONValue] = try? container.decode([String: OGTJSONValue].self) {
            self = .object(objectValue)
            return
        }
        let context: DecodingError.Context = DecodingError.Context(
            codingPath: decoder.codingPath,
            debugDescription: "Unsupported JSON value for OGTJSONValue."
        )
        throw DecodingError.dataCorrupted(context)
    }

    public func encode(to encoder: Encoder) throws {
        var container: SingleValueEncodingContainer = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }
}
