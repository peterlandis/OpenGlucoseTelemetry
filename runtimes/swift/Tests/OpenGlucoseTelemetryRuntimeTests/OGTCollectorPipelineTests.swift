import XCTest
@testable import OpenGlucoseTelemetryRuntime

final class OGTCollectorPipelineTests: XCTestCase {
    func testDecodeHealthKitSampleEnvelope() throws {
        let fileURL: URL = URL(fileURLWithPath: "\(#filePath)", isDirectory: false)
        let root: URL = try OGTRepositoryRoot.find(startingAt: fileURL)
        let sampleURL: URL = root.appendingPathComponent("examples/ingestion/healthkit-sample.json", isDirectory: false)
        let data: Data = try Data(contentsOf: sampleURL)
        let envelope: OGTIngestionEnvelope = try OGTIngestionEnvelope.decode(from: data)
        XCTAssertEqual(envelope.source, OGTHealthKitIngestAdapter.sourceId)
        XCTAssertEqual(envelope.traceId, "550e8400-e29b-41d4-a716-446655440000")
    }

    func testReferencePipelineHealthKitFixtureSucceeds() throws {
        let fileURL: URL = URL(fileURLWithPath: "\(#filePath)", isDirectory: false)
        let root: URL = try OGTRepositoryRoot.find(startingAt: fileURL)
        let sampleURL: URL = root.appendingPathComponent("examples/ingestion/healthkit-sample.json", isDirectory: false)
        let data: Data = try Data(contentsOf: sampleURL)
        let envelope: OGTIngestionEnvelope = try OGTIngestionEnvelope.decode(from: data)
        let pipeline: OGTReferenceCollectorPipeline = OGTReferenceCollectorPipeline()
        let result: OGTPipelineSubmitResult = pipeline.submit(envelope: envelope)
        guard case .success(let reading) = result else {
            XCTFail("Expected success, got \(String(describing: result))")
            return
        }
        XCTAssertEqual(reading.subjectId, "local:iphone:demo-subject")
        XCTAssertEqual(reading.unit, "mg/dL")
        XCTAssertEqual(reading.value, 142.0, accuracy: 0.01)
        XCTAssertEqual(reading.measurementSource, "cgm")
        XCTAssertEqual(reading.device.type, "cgm")
    }

    func testUnknownSourceReturnsAdapterUnknown() throws {
        let envelope: OGTIngestionEnvelope = OGTIngestionEnvelope(
            source: "unknown-vendor",
            payload: .object([:]),
            receivedAt: "2026-01-01T00:00:00.000Z",
            traceId: "trace-1",
            adapter: OGTAdapterWireMetadata(id: "ogt.adapter.unknown", version: "0.1.0")
        )
        let pipeline: OGTReferenceCollectorPipeline = OGTReferenceCollectorPipeline()
        let result: OGTPipelineSubmitResult = pipeline.submit(envelope: envelope)
        guard case .failure(let err) = result else {
            XCTFail("Expected failure")
            return
        }
        XCTAssertEqual(err.code, .adapterUnknown)
        XCTAssertEqual(err.field, "source")
    }
}
