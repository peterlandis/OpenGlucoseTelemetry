// swift-tools-version: 5.10
import PackageDescription

let package: Package = Package(
    name: "OpenGlucoseTelemetryRuntime",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
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
            ],
            resources: [
                .process("spec")
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
