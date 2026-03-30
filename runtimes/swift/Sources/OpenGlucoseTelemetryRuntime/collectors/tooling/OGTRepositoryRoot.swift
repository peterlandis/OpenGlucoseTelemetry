import Foundation

// MARK: - Repository root (schema paths)

/// Locates the OGT repository root by walking upward until `spec/ingestion-envelope.schema.json` exists.
/// Mirrors the TypeScript helper in `runtimes/typescript/collectors/tooling/paths.ts`.
public enum OGTRepositoryRoot {
    public static func find(startingAt url: URL) throws -> URL {
        var current: URL = url
        if !url.hasDirectoryPath {
            current = url.deletingLastPathComponent()
        }
        let maxDepth: Int = 12
        for _ in 0..<maxDepth {
            let marker: URL = current.appendingPathComponent("spec/ingestion-envelope.schema.json", isDirectory: false)
            if FileManager.default.fileExists(atPath: marker.path) {
                return current
            }
            let parent: URL = current.deletingLastPathComponent()
            if parent.path == current.path {
                break
            }
            current = parent
        }
        throw OGTRepositoryRootError.missingSpecMarker
    }
}

public enum OGTRepositoryRootError: Error {
    case missingSpecMarker
}

extension OGTRepositoryRootError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingSpecMarker:
            return
                "Could not locate OGT repository root (missing spec/ingestion-envelope.schema.json). Use a full checkout of OpenGlucoseTelemetry or pass a URL under that tree."
        }
    }
}
