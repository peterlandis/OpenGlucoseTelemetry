import XCTest
@testable import OpenGlucoseTelemetryRuntime

final class OGTRepositoryRootTests: XCTestCase {
    func testFindFromThisTestFileLocatesSpecMarker() throws {
        let fileURL: URL = URL(fileURLWithPath: "\(#filePath)", isDirectory: false)
        let root: URL = try OGTRepositoryRoot.find(startingAt: fileURL)
        let specURL: URL = root.appendingPathComponent("spec/ingestion-envelope.schema.json", isDirectory: false)
        XCTAssertTrue(FileManager.default.fileExists(atPath: specURL.path), "Expected spec marker at \(specURL.path)")
    }
}
