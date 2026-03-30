// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "OpenGlucoseTelemetryRuntime",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "OpenGlucoseTelemetryRuntime",
            targets: ["OpenGlucoseTelemetryRuntime"]
        ),
        .executable(
            name: "RunPipelineExample",
            targets: ["RunPipelineExample"]
        ),
    ],
    targets: [
        .target(
            name: "OpenGlucoseTelemetryRuntime",
            path: "Sources/OpenGlucoseTelemetryRuntime",
            exclude: [
                "collectors/README.md",
                "adapters/README.md",
            ]
        ),
        .testTarget(
            name: "OpenGlucoseTelemetryRuntimeTests",
            dependencies: ["OpenGlucoseTelemetryRuntime"],
            path: "Tests/OpenGlucoseTelemetryRuntimeTests"
        ),
        .executableTarget(
            name: "RunPipelineExample",
            dependencies: ["OpenGlucoseTelemetryRuntime"],
            path: "examples/RunPipelineExample"
        ),
    ]
)
