// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MacBarMonitor",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "MacBarMonitor",
            path: "Sources/MacBarMonitor",
            exclude: ["Info.plist"],
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("Foundation")
            ]
        ),
        .testTarget(
            name: "MacBarMonitorTests",
            dependencies: ["MacBarMonitor"],
            path: "Tests/MacBarMonitorTests",
            linkerSettings: [
                .linkedFramework("XCTest")
            ]
        )
    ]
)
