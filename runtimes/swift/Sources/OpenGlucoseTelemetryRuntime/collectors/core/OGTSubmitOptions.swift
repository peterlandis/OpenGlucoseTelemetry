import Foundation

/// Options for `OGTReferenceCollector.submit` (e.g. dedupe, test registry). Not `Sendable` when using `OGTDedupeTracker`.
public struct OGTSubmitOptions {
    public var dedupeTracker: OGTDedupeTracker?
    /// When `nil`, `OGTCollectorEngine` uses `OGTDefaultAdapterRegistry`.
    public var adapterRegistry: (any OGTAdapterRegistry)?

    public init(
        dedupeTracker: OGTDedupeTracker? = nil,
        adapterRegistry: (any OGTAdapterRegistry)? = nil
    ) {
        self.dedupeTracker = dedupeTracker
        self.adapterRegistry = adapterRegistry
    }
}
