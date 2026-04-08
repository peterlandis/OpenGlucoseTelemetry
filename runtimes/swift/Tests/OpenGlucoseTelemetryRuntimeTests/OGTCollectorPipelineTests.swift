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
        let pipeline: OGTReferenceCollector = OGTReferenceCollector()
        let result: OGTPipelineResult = pipeline.submit(envelope: envelope)
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

    func testReferencePipelineDexcomFixtureSucceeds() throws {
        let fileURL: URL = URL(fileURLWithPath: "\(#filePath)", isDirectory: false)
        let root: URL = try OGTRepositoryRoot.find(startingAt: fileURL)
        let sampleURL: URL = root.appendingPathComponent("examples/ingestion/dexcom-sample.json", isDirectory: false)
        let data: Data = try Data(contentsOf: sampleURL)
        let envelope: OGTIngestionEnvelope = try OGTIngestionEnvelope.decode(from: data)
        let pipeline: OGTReferenceCollector = OGTReferenceCollector()
        let result: OGTPipelineResult = pipeline.submit(envelope: envelope)
        guard case .success(let reading) = result else {
            XCTFail("Expected success, got \(String(describing: result))")
            return
        }
        XCTAssertEqual(reading.unit, "mg/dL")
        XCTAssertEqual(reading.value, 118.0, accuracy: 0.01)
        XCTAssertEqual(reading.provenance.sourceSystem, "dexcom")
    }

    func testPinnedOGISSchemaResourceLoads() throws {
        let data: Data = try OGTGlucoseReadingJSONSchemaResource.schemaData()
        XCTAssertFalse(data.isEmpty)
    }

    func testReferencePipelineHealthKitBadUnitFixtureFailsWithPayloadInvalid() throws {
        let fileURL: URL = URL(fileURLWithPath: "\(#filePath)", isDirectory: false)
        let root: URL = try OGTRepositoryRoot.find(startingAt: fileURL)
        let sampleURL: URL = root.appendingPathComponent("examples/ingestion/negative-healthkit-bad-unit.json", isDirectory: false)
        let data: Data = try Data(contentsOf: sampleURL)
        let envelope: OGTIngestionEnvelope = try OGTIngestionEnvelope.decode(from: data)
        let pipeline: OGTReferenceCollector = OGTReferenceCollector()
        let result: OGTPipelineResult = pipeline.submit(envelope: envelope)
        guard case .failure(let err) = result else {
            XCTFail("Expected failure")
            return
        }
        XCTAssertEqual(err.code, .payloadInvalid)
        XCTAssertEqual(err.field, "payload")
    }

    func testReferencePipelineHealthKitFutureFixtureFailsWithSemanticInvalid() throws {
        let fileURL: URL = URL(fileURLWithPath: "\(#filePath)", isDirectory: false)
        let root: URL = try OGTRepositoryRoot.find(startingAt: fileURL)
        let sampleURL: URL = root.appendingPathComponent("examples/ingestion/negative-healthkit-future.json", isDirectory: false)
        let data: Data = try Data(contentsOf: sampleURL)
        let envelope: OGTIngestionEnvelope = try OGTIngestionEnvelope.decode(from: data)
        let pipeline: OGTReferenceCollector = OGTReferenceCollector()
        let result: OGTPipelineResult = pipeline.submit(envelope: envelope)
        guard case .failure(let err) = result else {
            XCTFail("Expected failure")
            return
        }
        XCTAssertEqual(err.code, .semanticInvalid)
        XCTAssertEqual(err.field, "observed_at")
    }

    func testReferencePipelineManualSourceSucceeds() throws {
        let envelope: OGTIngestionEnvelope = OGTIngestionEnvelope(
            source: OGTManualIngestAdapter.sourceId,
            payload: .object(
                [
                    "subject_id": .string("local:test:manual"),
                    "value": .number(123.0),
                    "unit": .string("mg/dL"),
                    "observed_at": .string("2026-03-29T12:00:00.000Z"),
                ]
            ),
            receivedAt: "2026-03-29T12:01:00.000Z",
            traceId: "manual-test-1",
            adapter: OGTAdapterWireMetadata(id: "ogt.adapter.manual", version: "0.1.0")
        )
        let pipeline: OGTReferenceCollector = OGTReferenceCollector()
        let result: OGTPipelineResult = pipeline.submit(envelope: envelope)
        guard case .success(let reading) = result else {
            XCTFail("Expected success, got \(String(describing: result))")
            return
        }
        XCTAssertEqual(reading.measurementSource, "manual")
        XCTAssertEqual(reading.unit, "mg/dL")
    }

    func testDedupeTrackerRejectsDuplicateSubmission() throws {
        let envelope: OGTIngestionEnvelope = OGTIngestionEnvelope(
            source: OGTDexcomIngestAdapter.sourceId,
            payload: .object(
                [
                    "event_id": .string("evt-1"),
                    "subject_id": .string("local:test:dedupe"),
                    "system_time": .string("2026-03-29T12:00:00.000Z"),
                    "display_time": .string("2026-03-29T12:00:00.000Z"),
                    "value": .number(120.0),
                    "unit": .string("mg/dL"),
                    "trend_arrow": .string("flat"),
                    "trend_rate": .number(0.0),
                    "trend_rate_unit": .string("mg/dL/min"),
                    "quality_status": .string("valid"),
                    "device_model": .string("G7"),
                ]
            ),
            receivedAt: "2026-03-29T12:01:00.000Z",
            traceId: "dedupe-test-1",
            adapter: OGTAdapterWireMetadata(id: "ogt.adapter.dexcom", version: "0.1.0")
        )

        let options: OGTSubmitOptions = OGTSubmitOptions(dedupeTracker: OGTDedupeTracker())
        let pipeline: OGTReferenceCollector = OGTReferenceCollector()

        let first: OGTPipelineResult = pipeline.submit(envelope: envelope, options: options)
        let second: OGTPipelineResult = pipeline.submit(envelope: envelope, options: options)

        guard case .success = first else {
            XCTFail("Expected first success")
            return
        }
        guard case .failure(let err) = second else {
            XCTFail("Expected second failure")
            return
        }
        XCTAssertEqual(err.code, .duplicateEvent)
    }

    func testReferencePipelineManualFixtureSucceeds() throws {
        let fileURL: URL = URL(fileURLWithPath: "\(#filePath)", isDirectory: false)
        let root: URL = try OGTRepositoryRoot.find(startingAt: fileURL)
        let sampleURL: URL = root.appendingPathComponent("examples/ingestion/manual-sample.json", isDirectory: false)
        let data: Data = try Data(contentsOf: sampleURL)
        let envelope: OGTIngestionEnvelope = try OGTIngestionEnvelope.decode(from: data)
        let pipeline: OGTReferenceCollector = OGTReferenceCollector()
        let result: OGTPipelineResult = pipeline.submit(envelope: envelope)
        guard case .success(let reading) = result else {
            XCTFail("Expected success, got \(String(describing: result))")
            return
        }
        XCTAssertEqual(reading.measurementSource, "manual")
        XCTAssertEqual(reading.unit, "mg/dL")
        XCTAssertEqual(reading.value, 123.0, accuracy: 0.01)
    }

    func testUnknownSourceReturnsAdapterUnknown() throws {
        let envelope: OGTIngestionEnvelope = OGTIngestionEnvelope(
            source: "unknown-vendor",
            payload: .object([:]),
            receivedAt: "2026-01-01T00:00:00.000Z",
            traceId: "trace-1",
            adapter: OGTAdapterWireMetadata(id: "ogt.adapter.unknown", version: "0.1.0")
        )
        let pipeline: OGTReferenceCollector = OGTReferenceCollector()
        let result: OGTPipelineResult = pipeline.submit(envelope: envelope)
        guard case .failure(let err) = result else {
            XCTFail("Expected failure")
            return
        }
        XCTAssertEqual(err.code, .adapterUnknown)
        XCTAssertEqual(err.field, "source")
    }

    /// `decode` / `epochMs` ASCII fast path must agree with ms-rounded dates from `encodeMillisUTC`.
    func testDecodeFastPathMatchesEncodeMillisUTC() {
        let samples: [Date] = [
            Date(timeIntervalSince1970: 0),
            Date(timeIntervalSince1970: 1_704_000_000.123),
            Date(timeIntervalSince1970: 1_800_000_000.999),
        ]
        for original: Date in samples {
            let wire: String = OGTRFC3339.encodeMillisUTC(original)
            let msRounded: Int64 = Int64((original.timeIntervalSince1970 * 1000.0).rounded(.down))
            let expected: Date = Date(timeIntervalSince1970: Double(msRounded) / 1000.0)
            guard let decoded: Date = OGTRFC3339.decode(wire) else {
                XCTFail("decode failed for \(wire)")
                return
            }
            XCTAssertEqual(decoded.timeIntervalSince1970, expected.timeIntervalSince1970, accuracy: 0.001, wire)
            let epoch: Int64? = OGTRFC3339.epochMs(wire)
            XCTAssertEqual(epoch, msRounded, wire)
        }
    }

    /// Bulk insight path uses trusted normalization; ensure it matches the ICU parse path when timestamps are `encodeMillisUTC` output.
    func testTrustedMillisNormalizationMatchesFullPathWhenEncodedFromDate() throws {
        let anchor: Date = Date(timeIntervalSince1970: 1_704_000_000.0)
        let observedWire: String = OGTRFC3339.encodeMillisUTC(anchor)
        let sourceRecWire: String = OGTRFC3339.encodeMillisUTC(anchor.addingTimeInterval(-60))
        let receivedWire: String = OGTRFC3339.encodeMillisUTC(anchor.addingTimeInterval(1))
        let ingestedWire: String = OGTRFC3339.encodeMillisUTC(anchor.addingTimeInterval(2))
        let envelopeWire: String = OGTRFC3339.encodeMillisUTC(anchor.addingTimeInterval(3))

        let reading: OGTCanonicalGlucoseReadingV1 = OGTCanonicalGlucoseReadingV1(
            eventType: "glucose.reading",
            eventVersion: "0.1",
            subjectId: "s1",
            observedAt: observedWire,
            sourceRecordedAt: sourceRecWire,
            receivedAt: receivedWire,
            value: 6.6,
            unit: "mmol/L",
            measurementSource: "cgm",
            device: OGTCanonicalDevice(type: "cgm", manufacturer: "  Acme  ", model: nil),
            provenance: OGTCanonicalProvenance(
                sourceSystem: "test",
                rawEventId: "evt-1",
                adapterVersion: "1",
                ingestedAt: ingestedWire
            ),
            trend: nil,
            quality: nil
        )

        let full: OGTCanonicalGlucoseReadingV1 = try ogtNormalizeCanonicalReading(
            reading: reading,
            envelopeReceivedAt: envelopeWire
        )
        let trusted: OGTCanonicalGlucoseReadingV1 = try ogtNormalizeCanonicalReadingTrustedMillisEncodedRFC3339(
            reading: reading,
            envelopeReceivedAt: envelopeWire
        )
        XCTAssertEqual(trusted, full)
    }
}
