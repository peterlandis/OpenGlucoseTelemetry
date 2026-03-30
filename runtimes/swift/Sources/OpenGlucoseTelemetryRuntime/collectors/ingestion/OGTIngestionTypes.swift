import Foundation

// Wire ingestion envelope: see `OGTIngestionEnvelope.swift`.

// MARK: - Legacy routing error (registry / unknown source before structured pipeline)

public enum OGTPipelineError: Error {
    case unknownSource(String)
}

extension OGTPipelineError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unknownSource(let source):
            return "Unknown ingestion source: \(source). Register an adapter under adapters/ for this source id."
        }
    }
}
