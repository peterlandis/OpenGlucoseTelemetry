import Foundation

enum OGTJSONSchemaValidator {
    enum ValidationError: LocalizedError, Equatable {
        case schemaInvalid(String)
        case typeMismatch(expected: String, actual: String)
        case missingRequiredProperty(String)
        case additionalPropertyNotAllowed(String)
        case enumViolation(String)
        case constViolation(String)
        case minLengthViolation(String)
        case exclusiveMinimumViolation
        case refNotFound(String)
        case formatViolation(String)
        case oneOfViolation
        case anyOfViolation
        case allOfViolation

        var errorDescription: String? {
            switch self {
            case let .schemaInvalid(message):
                return "JSON Schema invalid: \(message)"
            case let .typeMismatch(expected, actual):
                return "JSON Schema type mismatch: expected \(expected), got \(actual)"
            case let .missingRequiredProperty(name):
                return "JSON Schema missing required property: \(name)"
            case let .additionalPropertyNotAllowed(name):
                return "JSON Schema additionalProperties=false, found: \(name)"
            case let .enumViolation(message):
                return "JSON Schema enum violation: \(message)"
            case let .constViolation(message):
                return "JSON Schema const violation: \(message)"
            case let .minLengthViolation(message):
                return "JSON Schema minLength violation: \(message)"
            case .exclusiveMinimumViolation:
                return "JSON Schema exclusiveMinimum violation"
            case let .refNotFound(ref):
                return "JSON Schema $ref not found: \(ref)"
            case let .formatViolation(message):
                return "JSON Schema format violation: \(message)"
            case .oneOfViolation:
                return "JSON Schema oneOf violation"
            case .anyOfViolation:
                return "JSON Schema anyOf violation"
            case .allOfViolation:
                return "JSON Schema allOf violation"
            }
        }
    }

    static func validate(instance: Any, schema: [String: Any]) throws {
        try validate(instance: instance, schema: schema, rootSchema: schema)
    }

    private static func validate(instance: Any, schema: [String: Any], rootSchema: [String: Any]) throws {
        if let ref: String = schema["$ref"] as? String {
            let resolved: [String: Any] = try resolve(ref: ref, rootSchema: rootSchema)
            try validate(instance: instance, schema: resolved, rootSchema: rootSchema)
            return
        }

        if let allOfAny: Any = schema["allOf"] {
            guard let allOf: [[String: Any]] = allOfAny as? [[String: Any]] else {
                throw ValidationError.schemaInvalid("allOf must be an array of schemas")
            }
            do {
                for s: [String: Any] in allOf {
                    try validate(instance: instance, schema: s, rootSchema: rootSchema)
                }
            } catch {
                throw ValidationError.allOfViolation
            }
        }

        if let anyOfAny: Any = schema["anyOf"] {
            guard let anyOf: [[String: Any]] = anyOfAny as? [[String: Any]] else {
                throw ValidationError.schemaInvalid("anyOf must be an array of schemas")
            }
            var matched: Bool = false
            for s: [String: Any] in anyOf {
                if (try? validate(instance: instance, schema: s, rootSchema: rootSchema)) != nil {
                    matched = true
                    break
                }
            }
            if !matched { throw ValidationError.anyOfViolation }
        }

        if let oneOfAny: Any = schema["oneOf"] {
            guard let oneOf: [[String: Any]] = oneOfAny as? [[String: Any]] else {
                throw ValidationError.schemaInvalid("oneOf must be an array of schemas")
            }
            var matchCount: Int = 0
            for s: [String: Any] in oneOf {
                if (try? validate(instance: instance, schema: s, rootSchema: rootSchema)) != nil {
                    matchCount += 1
                }
            }
            if matchCount != 1 { throw ValidationError.oneOfViolation }
        }

        if let type: String = schema["type"] as? String {
            try validateType(instance: instance, expectedType: type)
        }

        if let constValue: Any = schema["const"] {
            if !jsonEquals(constValue, instance) {
                throw ValidationError.constViolation("expected \(String(describing: constValue))")
            }
        }

        if let enumValues: [Any] = schema["enum"] as? [Any] {
            let ok: Bool = enumValues.contains { jsonEquals($0, instance) }
            if !ok { throw ValidationError.enumViolation("value \(String(describing: instance)) not in enum") }
        }

        if let minLength: Int = schema["minLength"] as? Int {
            guard let s: String = instance as? String else {
                throw ValidationError.typeMismatch(expected: "string", actual: typeName(instance))
            }
            if s.count < minLength { throw ValidationError.minLengthViolation("minLength=\(minLength)") }
        }

        if let format: String = schema["format"] as? String {
            try validateFormat(instance: instance, format: format)
        }

        if schema["exclusiveMinimum"] != nil {
            guard let n: Double = asDouble(instance) else {
                throw ValidationError.typeMismatch(expected: "number", actual: typeName(instance))
            }
            if !(n > 0) { throw ValidationError.exclusiveMinimumViolation }
        }

        if (schema["type"] as? String) == "array" || schema["items"] != nil {
            guard let arr: [Any] = instance as? [Any] else {
                throw ValidationError.typeMismatch(expected: "array", actual: typeName(instance))
            }
            if let itemsAny: Any = schema["items"] {
                guard let itemsSchema: [String: Any] = itemsAny as? [String: Any] else {
                    throw ValidationError.schemaInvalid("items must be a schema object")
                }
                for item: Any in arr {
                    try validate(instance: item, schema: itemsSchema, rootSchema: rootSchema)
                }
            }
        }

        if (schema["type"] as? String) == "object" || schema["properties"] != nil || schema["required"] != nil {
            guard let obj: [String: Any] = instance as? [String: Any] else {
                throw ValidationError.typeMismatch(expected: "object", actual: typeName(instance))
            }

            let required: [String] = schema["required"] as? [String] ?? []
            for key: String in required where obj[key] == nil {
                throw ValidationError.missingRequiredProperty(key)
            }

            let properties: [String: Any] = schema["properties"] as? [String: Any] ?? [:]
            for (key, value) in obj {
                if let propertySchemaAny: Any = properties[key] {
                    guard let propertySchema: [String: Any] = propertySchemaAny as? [String: Any] else {
                        throw ValidationError.schemaInvalid("properties.\(key) must be an object schema")
                    }
                    try validate(instance: value, schema: propertySchema, rootSchema: rootSchema)
                } else if let additional: Bool = schema["additionalProperties"] as? Bool, additional == false {
                    throw ValidationError.additionalPropertyNotAllowed(key)
                }
            }
        }
    }

    private static func validateType(instance: Any, expectedType: String) throws {
        switch expectedType {
        case "object":
            if !(instance is [String: Any]) { throw ValidationError.typeMismatch(expected: "object", actual: typeName(instance)) }
        case "string":
            if !(instance is String) { throw ValidationError.typeMismatch(expected: "string", actual: typeName(instance)) }
        case "number":
            if asDouble(instance) == nil { throw ValidationError.typeMismatch(expected: "number", actual: typeName(instance)) }
        case "array":
            if !(instance is [Any]) { throw ValidationError.typeMismatch(expected: "array", actual: typeName(instance)) }
        default:
            throw ValidationError.schemaInvalid("Unsupported type: \(expectedType)")
        }
    }

    private static func validateFormat(instance: Any, format: String) throws {
        switch format {
        case "date-time":
            guard let s: String = instance as? String else {
                throw ValidationError.typeMismatch(expected: "string", actual: typeName(instance))
            }
            if parseISO8601DateTime(s) == nil {
                throw ValidationError.formatViolation("date-time: \(s)")
            }
        default:
            return
        }
    }

    private static func parseISO8601DateTime(_ s: String) -> Date? {
        let f1: ISO8601DateFormatter = {
            let f: ISO8601DateFormatter = .init()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f
        }()
        if let d: Date = f1.date(from: s) { return d }
        let f2: ISO8601DateFormatter = {
            let f: ISO8601DateFormatter = .init()
            f.formatOptions = [.withInternetDateTime]
            return f
        }()
        return f2.date(from: s)
    }

    private static func resolve(ref: String, rootSchema: [String: Any]) throws -> [String: Any] {
        guard ref.hasPrefix("#/") else { throw ValidationError.refNotFound(ref) }
        let parts: [String] = ref.dropFirst(2).split(separator: "/").map { String($0) }
        var current: Any = rootSchema
        for part: String in parts {
            guard let dict: [String: Any] = current as? [String: Any], let next: Any = dict[part] else {
                throw ValidationError.refNotFound(ref)
            }
            current = next
        }
        guard let resolved: [String: Any] = current as? [String: Any] else {
            throw ValidationError.refNotFound(ref)
        }
        return resolved
    }

    private static func typeName(_ value: Any) -> String {
        if value is [String: Any] { return "object" }
        if value is String { return "string" }
        if asDouble(value) != nil { return "number" }
        if value is [Any] { return "array" }
        if value is NSNull { return "null" }
        return String(describing: Swift.type(of: value))
    }

    private static func asDouble(_ value: Any) -> Double? {
        if let d: Double = value as? Double { return d }
        if let i: Int = value as? Int { return Double(i) }
        if let n: NSNumber = value as? NSNumber { return n.doubleValue }
        return nil
    }

    private static func jsonEquals(_ a: Any, _ b: Any) -> Bool {
        switch (a, b) {
        case let (x as String, y as String):
            return x == y
        case let (x as NSNumber, y as NSNumber):
            return x == y
        case let (x as Int, y as Int):
            return x == y
        case let (x as Double, y as Double):
            return x == y
        default:
            return String(describing: a) == String(describing: b)
        }
    }
}

