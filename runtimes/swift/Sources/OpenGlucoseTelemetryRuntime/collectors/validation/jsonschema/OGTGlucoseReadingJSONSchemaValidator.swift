import Foundation

/// Validates an OGIS `glucose.reading` JSON object against the pinned JSON Schema.
enum OGTGlucoseReadingJSONSchemaValidator {
    static func validateJSONObject(_ object: [String: Any]) throws {
        let schema: [String: Any] = try OGTGlucoseReadingJSONSchemaResource.schemaObject()
        try OGTJSONSchemaValidator.validate(instance: object, schema: schema)
    }
}

