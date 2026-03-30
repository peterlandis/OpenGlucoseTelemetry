import Foundation

/// Optional in-memory dedupe for MVP (parity with `dedupe.ts`). Key: subject_id + observed_at + raw_event_id.
public final class OGTDedupeTracker: @unchecked Sendable {
    private var seen: Set<String> = []
    private let lock: NSLock = NSLock()

    public init() {}

    public func makeKey(subjectId: String, observedAt: String, rawEventId: String) -> String {
        "\(subjectId)\u{001f}\(observedAt)\u{001f}\(rawEventId)"
    }

    public func checkAndRemember(key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if seen.contains(key) {
            return false
        }
        seen.insert(key)
        return true
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        seen.removeAll()
    }
}

/// Options for `OGTReferenceCollectorPipeline.submit` (e.g. dedupe, test registry). Not `Sendable` when using `OGTDedupeTracker`.
public struct OGTSubmitOptions {
    public var dedupeTracker: OGTDedupeTracker?
    /// When `nil`, `OGTCollectorSubmit` uses `OGTDefaultAdapterRegistry`.
    public var adapterRegistry: (any OGTAdapterRegistry)?

    public init(
        dedupeTracker: OGTDedupeTracker? = nil,
        adapterRegistry: (any OGTAdapterRegistry)? = nil
    ) {
        self.dedupeTracker = dedupeTracker
        self.adapterRegistry = adapterRegistry
    }
}
