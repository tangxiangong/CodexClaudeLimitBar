// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CodexClaudeLimitBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "CodexClaudeLimitCore",
            targets: ["CodexClaudeLimitCore"]
        ),
        .executable(
            name: "CodexClaudeLimitBar",
            targets: ["CodexClaudeLimitBar"]
        )
    ],
    targets: [
        .target(
            name: "CodexClaudeLimitCore",
            path: "Sources/CodexClaudeLimitCore"
        ),
        .executableTarget(
            name: "CodexClaudeLimitBar",
            dependencies: ["CodexClaudeLimitCore"],
            path: "Sources/CodexClaudeLimitBar",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
