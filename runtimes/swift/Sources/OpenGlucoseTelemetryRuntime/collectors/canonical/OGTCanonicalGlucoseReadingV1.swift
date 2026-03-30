import Foundation

// MARK: - OGIS glucose.reading v0.1 (canonical wire shape)

/// Canonical glucose reading aligned with `spec/pinned/glucose.reading.v0_1.json` and TypeScript `CanonicalGlucoseReadingV01` (Swift type name **`OGTCanonicalGlucoseReadingV1`**).
public struct OGTCanonicalGlucoseReadingV1: Codable, Sendable, Equatable {
    public var eventType: String
    public var eventVersion: String
    public var subjectId: String
    public var observedAt: String
    public var sourceRecordedAt: String?
    public var receivedAt: String?
    public var value: Double
    public var unit: String
    public var measurementSource: String
    public var device: OGTCanonicalDevice
    public var provenance: OGTCanonicalProvenance
    public var trend: OGTCanonicalTrend?
    public var quality: OGTCanonicalQuality?

    enum CodingKeys: String, CodingKey {
        case eventType = "event_type"
        case eventVersion = "event_version"
        case subjectId = "subject_id"
        case observedAt = "observed_at"
        case sourceRecordedAt = "source_recorded_at"
        case receivedAt = "received_at"
        case value
        case unit
        case measurementSource = "measurement_source"
        case device
        case provenance
        case trend
        case quality
    }

    public init(
        eventType: String,
        eventVersion: String,
        subjectId: String,
        observedAt: String,
        sourceRecordedAt: String? = nil,
        receivedAt: String? = nil,
        value: Double,
        unit: String,
        measurementSource: String,
        device: OGTCanonicalDevice,
        provenance: OGTCanonicalProvenance,
        trend: OGTCanonicalTrend? = nil,
        quality: OGTCanonicalQuality? = nil
    ) {
        self.eventType = eventType
        self.eventVersion = eventVersion
        self.subjectId = subjectId
        self.observedAt = observedAt
        self.sourceRecordedAt = sourceRecordedAt
        self.receivedAt = receivedAt
        self.value = value
        self.unit = unit
        self.measurementSource = measurementSource
        self.device = device
        self.provenance = provenance
        self.trend = trend
        self.quality = quality
    }
}

public struct OGTCanonicalDevice: Codable, Sendable, Equatable {
    public var type: String
    public var manufacturer: String?
    public var model: String?

    public init(type: String, manufacturer: String? = nil, model: String? = nil) {
        self.type = type
        self.manufacturer = manufacturer
        self.model = model
    }
}

public struct OGTCanonicalProvenance: Codable, Sendable, Equatable {
    public var sourceSystem: String
    public var rawEventId: String
    public var adapterVersion: String
    public var ingestedAt: String

    enum CodingKeys: String, CodingKey {
        case sourceSystem = "source_system"
        case rawEventId = "raw_event_id"
        case adapterVersion = "adapter_version"
        case ingestedAt = "ingested_at"
    }

    public init(sourceSystem: String, rawEventId: String, adapterVersion: String, ingestedAt: String) {
        self.sourceSystem = sourceSystem
        self.rawEventId = rawEventId
        self.adapterVersion = adapterVersion
        self.ingestedAt = ingestedAt
    }
}

public struct OGTCanonicalTrend: Codable, Sendable, Equatable {
    public var direction: String?
    public var rate: Double?
    public var rateUnit: String?

    enum CodingKeys: String, CodingKey {
        case direction
        case rate
        case rateUnit = "rate_unit"
    }

    public init(direction: String? = nil, rate: Double? = nil, rateUnit: String? = nil) {
        self.direction = direction
        self.rate = rate
        self.rateUnit = rateUnit
    }
}

public struct OGTCanonicalQuality: Codable, Sendable, Equatable {
    public var status: String?

    public init(status: String? = nil) {
        self.status = status
    }
}

public extension OGTCanonicalGlucoseReadingV1 {
    /// Encodes to JSON `Data` with snake_case keys (OGIS wire shape).
    func encodeToCanonicalJSONData() throws -> Data {
        let encoder: JSONEncoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(self)
    }
}
