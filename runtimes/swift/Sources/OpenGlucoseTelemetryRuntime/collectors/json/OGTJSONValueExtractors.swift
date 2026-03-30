import Foundation

// MARK: - Extractors (OGTJSONValue → typed values)

public enum OGTJSONExtractError: Error, Sendable, Equatable {
    case expectedObject
    case missingKey(String)
    case wrongType(String)
    case unknownPayloadKey(String)
}

extension OGTJSONExtractError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .expectedObject:
            return "Expected JSON object"
        case .missingKey(let k):
            return "Missing key: \(k)"
        case .wrongType(let m):
            return m
        case .unknownPayloadKey(let k):
            return "Unknown payload key: \(k)"
        }
    }
}

public func ogtRequireObject(_ value: OGTJSONValue) throws -> [String: OGTJSONValue] {
    if case .object(let o) = value {
        return o
    }
    throw OGTJSONExtractError.expectedObject
}

public func ogtRequireString(_ object: [String: OGTJSONValue], key: String) throws -> String {
    guard let v: OGTJSONValue = object[key] else {
        throw OGTJSONExtractError.missingKey(key)
    }
    if case .string(let s) = v {
        return s
    }
    throw OGTJSONExtractError.wrongType("Expected string for \(key)")
}

public func ogtOptionalString(_ object: [String: OGTJSONValue], key: String) throws -> String? {
    guard let v: OGTJSONValue = object[key] else {
        return nil
    }
    if case .null = v {
        return nil
    }
    if case .string(let s) = v {
        return s
    }
    throw OGTJSONExtractError.wrongType("Expected string or null for \(key)")
}

public func ogtRequireNumber(_ object: [String: OGTJSONValue], key: String) throws -> Double {
    guard let v: OGTJSONValue = object[key] else {
        throw OGTJSONExtractError.missingKey(key)
    }
    if case .number(let n) = v {
        return n
    }
    if case .bool = v {
        throw OGTJSONExtractError.wrongType("Expected number for \(key)")
    }
    if case .string = v {
        throw OGTJSONExtractError.wrongType("Expected number for \(key)")
    }
    throw OGTJSONExtractError.wrongType("Expected number for \(key)")
}

public func ogtOptionalNumber(_ object: [String: OGTJSONValue], key: String) throws -> Double? {
    guard let v: OGTJSONValue = object[key] else {
        return nil
    }
    if case .null = v {
        return nil
    }
    if case .number(let n) = v {
        return n
    }
    throw OGTJSONExtractError.wrongType("Expected number or null for \(key)")
}

public func ogtOptionalObject(_ object: [String: OGTJSONValue], key: String) throws -> [String: OGTJSONValue]? {
    guard let v: OGTJSONValue = object[key] else {
        return nil
    }
    if case .null = v {
        return nil
    }
    if case .object(let o) = v {
        return o
    }
    throw OGTJSONExtractError.wrongType("Expected object for \(key)")
}

/// Rejects keys outside `allowed` (additionalProperties: false parity).
public func ogtAssertOnlyKeys(_ object: [String: OGTJSONValue], allowed: Set<String>) throws {
    for key: String in object.keys where !allowed.contains(key) {
        throw OGTJSONExtractError.unknownPayloadKey(key)
    }
}
