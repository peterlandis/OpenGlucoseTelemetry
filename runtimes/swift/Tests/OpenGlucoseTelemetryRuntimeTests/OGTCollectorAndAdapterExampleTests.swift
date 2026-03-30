import XCTest
@testable import OpenGlucoseTelemetryRuntime

/// Examples for wiring **collectors** (`OGTReferenceCollector`) and **adapters** (`OGTAdapterRegistry` + `adapters/*`).
///
/// **Flow:** Decode JSON → `OGTIngestionEnvelope` → `OGTCollectorPipeline.submit` → validate → registry `mapPayload` → normalize → semantic → optional dedupe → OGIS check → `OGTPipelineResult`.

final class OGTCollectorAndAdapterExampleTests: XCTestCase {
    // MARK: - Example 1: Inject a stub registry via `OGTSubmitOptions` (unit-test pattern)

    /// Minimal registry that maps only `mock` to a fixed canonical reading (bypasses real `OGTMockIngestAdapter` mapping).
    private struct ExampleStubRegistry: OGTAdapterRegistry, Sendable {
        func validatePayload(for source: String, payload: OGTJSONValue) throws {
            guard source == OGTMockIngestAdapter.sourceId else {
                throw OGTPipelineError.unknownSource(source)
            }
            try ogtValidateMockPayload(payload)
        }

        func mapPayload(
            for source: String,
            payload: OGTJSONValue,
            envelope: OGTIngestionEnvelope
        ) throws -> OGTCanonicalGlucoseReadingV1 {
            guard source == OGTMockIngestAdapter.sourceId else {
                throw OGTPipelineError.unknownSource(source)
            }
            _ = payload
            return OGTCanonicalGlucoseReadingV1(
                eventType: "glucose.reading",
                eventVersion: "0.1",
                subjectId: "stub-subject",
                observedAt: "2020-01-15T12:00:00.000Z",
                sourceRecordedAt: nil,
                receivedAt: nil,
                value: 5.5,
                unit: "mmol/L",
                measurementSource: "manual",
                device: OGTCanonicalDevice(type: "app", manufacturer: "stub", model: nil),
                provenance: OGTCanonicalProvenance(
                    sourceSystem: "test.stub",
                    rawEventId: "stub-raw-1",
                    adapterVersion: envelope.adapter.version,
                    ingestedAt: envelope.receivedAt
                ),
                trend: nil,
                quality: nil
            )
        }
    }

    func testExample_stubRegistry_collectorReturnsSuccess() throws {
        let json: String = """
        {
          "source": "mock",
          "payload": {
            "subject_id": "local:mock:1",
            "value": 5.5,
            "unit": "mmol/L",
            "observed_at": "2026-03-29T10:00:00.000Z"
          },
          "received_at": "2026-03-29T10:00:01.000Z",
          "trace_id": "trace-mock-example",
          "adapter": { "id": "ogt.adapter.mock", "version": "0.1.0" }
        }
        """
        let data: Data = Data(json.utf8)
        let envelope: OGTIngestionEnvelope = try OGTIngestionEnvelope.decode(from: data)

        let pipeline: OGTCollectorPipeline = OGTReferenceCollector()
        let result: OGTPipelineResult = pipeline.submit(
            envelope: envelope,
            options: OGTSubmitOptions(adapterRegistry: ExampleStubRegistry())
        )

        guard case .success(let reading) = result else {
            XCTFail("Expected success, got \(String(describing: result))")
            return
        }
        XCTAssertEqual(reading.subjectId, "stub-subject")
        XCTAssertEqual(reading.unit, "mg/dL")
    }

    // MARK: - Example 2: Repo fixture + default registry → real HealthKit adapter

    func testExample_defaultRegistry_dispatchesToHealthKitAdapter() throws {
        let fileURL: URL = URL(fileURLWithPath: "\(#filePath)", isDirectory: false)
        let root: URL = try OGTRepositoryRoot.find(startingAt: fileURL)
        let sampleURL: URL = root.appendingPathComponent("examples/ingestion/healthkit-sample.json", isDirectory: false)
        let data: Data = try Data(contentsOf: sampleURL)
        let envelope: OGTIngestionEnvelope = try OGTIngestionEnvelope.decode(from: data)

        let pipeline: OGTReferenceCollector = OGTReferenceCollector()
        XCTAssertEqual(envelope.source, OGTHealthKitIngestAdapter.sourceId)

        let result: OGTPipelineResult = pipeline.submit(envelope: envelope)
        guard case .success(let reading) = result else {
            XCTFail("Expected success, got \(String(describing: result))")
            return
        }
        XCTAssertEqual(reading.provenance.sourceSystem, "com.apple.health")
        XCTAssertEqual(reading.provenance.rawEventId, "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")
    }

    // MARK: - Example 3: Depend on the protocol (app injection / tests)

    func testExample_injectCollectorPipelineProtocol() throws {
        let json: String = """
        {
          "source": "mock",
          "payload": { "subject_id": "x", "value": 100, "unit": "mg/dL", "observed_at": "2020-06-01T12:00:00.000Z" },
          "received_at": "2026-03-29T12:00:01.000Z",
          "trace_id": "trace-inject",
          "adapter": { "id": "ogt.adapter.mock", "version": "0.1.0" }
        }
        """
        let envelope: OGTIngestionEnvelope = try OGTIngestionEnvelope.decode(from: Data(json.utf8))

        let collector: OGTCollectorPipeline = OGTReferenceCollector()
        let result: OGTPipelineResult = collector.submit(envelope: envelope)
        guard case .success(let out) = result else {
            XCTFail("Expected success, got \(String(describing: result))")
            return
        }
        XCTAssertEqual(out.eventVersion, "0.1")
        XCTAssertEqual(out.subjectId, "x")
    }
}
