import Foundation

// MARK: - Adapter registry

/// Dispatches `source` strings to registered **validate + map** pairs (pluggable adapters).
public protocol OGTAdapterRegistry: Sendable {
    func validatePayload(for source: String, payload: OGTJSONValue) throws

    func mapPayload(
        for source: String,
        payload: OGTJSONValue,
        envelope: OGTIngestionEnvelope
    ) throws -> OGTCanonicalGlucoseReadingV1
}

/// Default registry: built from [`OGTAdapterCatalog.builtinRegistrations`](./OGTAdapterCatalog.swift).
/// Use **`init(registrations:)`** to supply a custom set (tests, apps with extra sources).
public struct OGTDefaultAdapterRegistry: OGTAdapterRegistry, Sendable {
    private let bySourceId: [String: OGTAdapterRegistration]

    /// Registers built-in MVP sources (`healthkit`, `dexcom`, `mock`).
    public init() {
        self.init(registrations: OGTAdapterCatalog.builtinRegistrations)
    }

    /// Builds a registry from explicit registrations. Duplicate `sourceId` is a programmer error.
    public init(registrations: [OGTAdapterRegistration]) {
        var map: [String: OGTAdapterRegistration] = [:]
        map.reserveCapacity(registrations.count)
        for reg: OGTAdapterRegistration in registrations {
            precondition(
                map[reg.sourceId] == nil,
                "Duplicate OGTAdapterRegistration sourceId: \(reg.sourceId)"
            )
            map[reg.sourceId] = reg
        }
        self.bySourceId = map
    }

    public func validatePayload(for source: String, payload: OGTJSONValue) throws {
        guard let reg: OGTAdapterRegistration = bySourceId[source] else {
            throw OGTPipelineError.unknownSource(source)
        }
        try reg.validatePayload(payload)
    }

    public func mapPayload(
        for source: String,
        payload: OGTJSONValue,
        envelope: OGTIngestionEnvelope
    ) throws -> OGTCanonicalGlucoseReadingV1 {
        guard let reg: OGTAdapterRegistration = bySourceId[source] else {
            throw OGTPipelineError.unknownSource(source)
        }
        return try reg.mapPayload(payload, envelope: envelope)
    }
}
