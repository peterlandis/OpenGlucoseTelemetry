import Foundation

// MARK: - Collector pipeline

/// End-to-end contract: envelope → validate → adapter map → normalize → semantic rules → optional dedupe → OGIS validation.
/// TypeScript reference: `runtimes/typescript/collectors/core/collector-engine.ts` (`submit`, re-exported from `pipeline.ts`).
public protocol OGTCollectorPipeline {
    func submit(
        envelope: OGTIngestionEnvelope,
        options: OGTSubmitOptions
    ) -> OGTPipelineResult
}

public extension OGTCollectorPipeline {
    func submit(envelope: OGTIngestionEnvelope) -> OGTPipelineResult {
        submit(envelope: envelope, options: OGTSubmitOptions())
    }
}

/// Reference pipeline (full Swift parity with TS `submit` for MVP sources).
public struct OGTReferenceCollector: OGTCollectorPipeline {
    public init() {}

    public func submit(
        envelope: OGTIngestionEnvelope,
        options: OGTSubmitOptions
    ) -> OGTPipelineResult {
        OGTCollectorEngine.run(envelope: envelope, options: options)
    }
}
