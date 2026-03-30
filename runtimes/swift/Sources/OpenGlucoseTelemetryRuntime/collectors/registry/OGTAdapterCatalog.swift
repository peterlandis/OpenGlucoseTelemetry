import Foundation

// MARK: - Built-in adapter catalog

/// **Single append point** for built-in sources: add `YourAdapter.ogtRegistration` here when you add `adapters/<source>/`.
/// The collector (`OGTCollectorEngine`) only talks to **`OGTAdapterRegistry`**; it has **no** per-source `switch`.
public enum OGTAdapterCatalog {
    public static let builtinRegistrations: [OGTAdapterRegistration] = [
        OGTHealthKitIngestAdapter.ogtRegistration,
        OGTDexcomIngestAdapter.ogtRegistration,
        OGTMockIngestAdapter.ogtRegistration,
    ]
}
