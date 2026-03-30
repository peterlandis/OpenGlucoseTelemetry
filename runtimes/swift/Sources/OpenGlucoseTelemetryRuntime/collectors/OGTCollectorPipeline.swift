import Foundation

// MARK: - Collector pipeline

/// End-to-end contract: envelope → validate → adapter map → normalize → semantic rules → optional dedupe → OGIS validation.
/// TypeScript reference: `runtimes/typescript/collectors/pipeline.ts` (`submit`).
public protocol OGTCollectorPipeline {
    func submit(
        envelope: OGTIngestionEnvelope,
        options: OGTSubmitOptions
    ) -> OGTPipelineSubmitResult
}

public extension OGTCollectorPipeline {
    func submit(envelope: OGTIngestionEnvelope) -> OGTPipelineSubmitResult {
        submit(envelope: envelope, options: OGTSubmitOptions())
    }
}

/// Reference pipeline (full Swift parity with TS `submit` for MVP sources).
public struct OGTReferenceCollectorPipeline: OGTCollectorPipeline {
    public init() {}

    public func submit(
        envelope: OGTIngestionEnvelope,
        options: OGTSubmitOptions
    ) -> OGTPipelineSubmitResult {
        OGTCollectorSubmit.run(envelope: envelope, options: options)
    }
}
