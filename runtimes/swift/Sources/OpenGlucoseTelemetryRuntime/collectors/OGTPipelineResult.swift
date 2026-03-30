import Foundation

// MARK: - Structured errors (parity with TS collectors/errors.ts)

public enum OGTPipelineIssueCode: String, Sendable, Codable {
    case envelopeInvalid = "ENVELOPE_INVALID"
    case payloadInvalid = "PAYLOAD_INVALID"
    case adapterUnknown = "ADAPTER_UNKNOWN"
    case mappingFailed = "MAPPING_FAILED"
    case semanticInvalid = "SEMANTIC_INVALID"
    case canonicalSchemaInvalid = "CANONICAL_SCHEMA_INVALID"
    case duplicateEvent = "DUPLICATE_EVENT"
}

public struct OGTStructuredPipelineError: Error, Sendable, Equatable {
    public let code: OGTPipelineIssueCode
    public let message: String
    public let traceId: String
    public let field: String?

    public init(code: OGTPipelineIssueCode, message: String, traceId: String, field: String? = nil) {
        self.code = code
        self.message = message
        self.traceId = traceId
        self.field = field
    }
}

extension OGTStructuredPipelineError: LocalizedError {
    public var errorDescription: String? {
        message
    }
}

// MARK: - Submit result (parity with TS PipelineResult)

public enum OGTPipelineSubmitResult: Sendable, Equatable {
    case success(OGTCanonicalGlucoseReadingV01)
    case failure(OGTStructuredPipelineError)

    public var reading: OGTCanonicalGlucoseReadingV01? {
        if case .success(let r) = self {
            return r
        }
        return nil
    }

    public var error: OGTStructuredPipelineError? {
        if case .failure(let e) = self {
            return e
        }
        return nil
    }
}
