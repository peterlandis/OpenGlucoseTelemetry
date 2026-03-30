import Foundation
import OpenGlucoseTelemetryRuntime

/// Small CLI: decode an ingestion envelope JSON, run `OGTReferenceCollector`, print canonical JSON or a structured error.
@main
private enum RunPipelineExample {
    static func main() {
        let args: [String] = CommandLine.arguments
        let jsonData: Data
        if args.count >= 2 {
            let path: String = args[1]
            let fileURL: URL = URL(fileURLWithPath: path, isDirectory: false)
            do {
                jsonData = try Data(contentsOf: fileURL)
            } catch {
                writeStderr("Could not read file: \(path)\n\(error)\n")
                exit(2)
            }
        } else {
            do {
                let cwd: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
                let root: URL = try OGTRepositoryRoot.find(startingAt: cwd)
                let sampleURL: URL = root.appendingPathComponent("examples/ingestion/healthkit-sample.json", isDirectory: false)
                jsonData = try Data(contentsOf: sampleURL)
            } catch {
                writeStderr(
                    "No JSON path argument and default fixture could not be loaded.\n" +
                        "Run from the OpenGlucoseTelemetry repo (or a parent directory that contains spec/), or pass a file path.\n" +
                        "\(error)\n"
                )
                writeStderr("Usage: swift run RunPipelineExample [path-to-ingestion-envelope.json]\n")
                exit(2)
            }
        }

        let envelope: OGTIngestionEnvelope
        do {
            envelope = try OGTIngestionEnvelope.decode(from: jsonData)
        } catch {
            writeStderr("Invalid ingestion envelope JSON: \(error)\n")
            exit(2)
        }

        let pipeline: OGTReferenceCollector = OGTReferenceCollector()
        let result: OGTPipelineResult = pipeline.submit(envelope: envelope)

        switch result {
        case .success(let reading):
            do {
                let encoder: JSONEncoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
                let pretty: Data = try encoder.encode(reading)
                guard let text: String = String(data: pretty, encoding: .utf8) else {
                    writeStderr("Could not encode output as UTF-8.\n")
                    exit(2)
                }
                print(text)
                exit(0)
            } catch {
                writeStderr("Could not encode canonical reading: \(error)\n")
                exit(2)
            }
        case .failure(let err):
            writeStderr("Pipeline failure\n")
            writeStderr("  code: \(err.code.rawValue)\n")
            writeStderr("  trace_id: \(err.traceId)\n")
            if let field: String = err.field {
                writeStderr("  field: \(field)\n")
            }
            writeStderr("  message: \(err.message)\n")
            exit(1)
        }
    }

    private static func writeStderr(_ message: String) {
        guard let data: Data = message.data(using: .utf8) else {
            return
        }
        FileHandle.standardError.write(data)
    }
}
