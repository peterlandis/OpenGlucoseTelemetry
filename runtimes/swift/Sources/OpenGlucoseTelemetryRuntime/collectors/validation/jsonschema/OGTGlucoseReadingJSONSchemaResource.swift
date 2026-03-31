import Foundation

enum OGTGlucoseReadingJSONSchemaResource {
    static func schemaData() throws -> Data {
        guard let url: URL = Bundle.module.url(forResource: "glucose.reading.v0_1", withExtension: "json") else {
            throw NSError(domain: "OGTJSONSchema", code: 1, userInfo: [NSLocalizedDescriptionKey: "Pinned glucose.reading.v0_1.json resource missing"])
        }
        return try Data(contentsOf: url, options: [.mappedIfSafe])
    }

    static func schemaObject() throws -> [String: Any] {
        let data: Data = try schemaData()
        let json: Any = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        guard let dict: [String: Any] = json as? [String: Any] else {
            throw NSError(domain: "OGTJSONSchema", code: 2, userInfo: [NSLocalizedDescriptionKey: "Schema root must be an object"])
        }
        return dict
    }
}

