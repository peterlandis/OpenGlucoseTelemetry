import Foundation

// MARK: - Full pipeline (parity with pipeline.ts `submit`)

/// Runs envelope validation → payload validation → adapter map → normalize → semantic rules → optional dedupe → OGIS schema validation.
public enum OGTCollectorSubmit {
    private static let defaultRegistry: OGTDefaultAdapterRegistry = OGTDefaultAdapterRegistry()

    public static func run(
        envelope: OGTIngestionEnvelope,
        options: OGTSubmitOptions = OGTSubmitOptions()
    ) -> OGTPipelineSubmitResult {
        let traceId: String = envelope.traceId

        if let envelopeErr: String = ogtValidateIngestionEnvelope(envelope) {
            return .failure(
                OGTStructuredPipelineError(
                    code: .envelopeInvalid,
                    message: envelopeErr,
                    traceId: traceId
                )
            )
        }

        do {
            try validatePayloadForSource(envelope)
        } catch let e as OGTPipelineError {
            switch e {
            case .unknownSource(let s):
                return .failure(
                    OGTStructuredPipelineError(
                        code: .adapterUnknown,
                        message: "Unsupported source: \(s)",
                        traceId: traceId,
                        field: "source"
                    )
                )
            }
        } catch {
            return .failure(payloadFailure(error, traceId: traceId, field: "payload"))
        }

        let registry: any OGTAdapterRegistry
        if let custom: any OGTAdapterRegistry = options.adapterRegistry {
            registry = custom
        } else {
            registry = Self.defaultRegistry
        }

        let mapped: OGTCanonicalGlucoseReadingV01
        do {
            mapped = try registry.mapPayload(
                for: envelope.source,
                payload: envelope.payload,
                envelope: envelope
            )
        } catch let e as OGTPipelineError {
            switch e {
            case .unknownSource(let s):
                return .failure(
                    OGTStructuredPipelineError(
                        code: .adapterUnknown,
                        message: "Unsupported source: \(s)",
                        traceId: traceId,
                        field: "source"
                    )
                )
            }
        } catch {
            return .failure(payloadFailure(error, traceId: traceId, field: "payload"))
        }

        let normalized: OGTCanonicalGlucoseReadingV01
        do {
            normalized = try ogtNormalizeCanonicalReading(
                reading: mapped,
                envelopeReceivedAt: envelope.receivedAt
            )
        } catch {
            let msg: String = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
            return .failure(
                OGTStructuredPipelineError(code: .mappingFailed, message: msg, traceId: traceId)
            )
        }

        if let sem: OGTStructuredPipelineError = ogtApplySemanticRules(reading: normalized, traceId: traceId) {
            return .failure(sem)
        }

        if let dedupe: OGTDedupeTracker = options.dedupeTracker {
            let key: String = dedupe.makeKey(
                subjectId: normalized.subjectId,
                observedAt: normalized.observedAt,
                rawEventId: normalized.provenance.rawEventId
            )
            if !dedupe.checkAndRemember(key: key) {
                return .failure(
                    OGTStructuredPipelineError(
                        code: .duplicateEvent,
                        message: "Duplicate ingestion key",
                        traceId: traceId
                    )
                )
            }
        }

        if let schemaMsg: String = ogtValidateGlucoseReadingOgis(normalized) {
            return .failure(
                OGTStructuredPipelineError(
                    code: .canonicalSchemaInvalid,
                    message: schemaMsg,
                    traceId: traceId
                )
            )
        }

        return .success(normalized)
    }

    private static func validatePayloadForSource(_ envelope: OGTIngestionEnvelope) throws {
        switch envelope.source {
        case OGTHealthKitIngestAdapter.sourceId:
            try ogtValidateHealthKitPayload(envelope.payload)
        case OGTMockIngestAdapter.sourceId:
            try ogtValidateMockPayload(envelope.payload)
        case OGTDexcomIngestAdapter.sourceId:
            try ogtValidateDexcomPayload(envelope.payload)
        default:
            throw OGTPipelineError.unknownSource(envelope.source)
        }
    }

    private static func payloadFailure(
        _ error: Error,
        traceId: String,
        field: String?
    ) -> OGTStructuredPipelineError {
        let msg: String = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
        return OGTStructuredPipelineError(code: .payloadInvalid, message: msg, traceId: traceId, field: field)
    }
}
