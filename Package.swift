// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AnalyticsKit",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "AnalyticsKit",
            targets: ["AnalyticsKit"]
        ),
    ],
    targets: [
        .target(
            name: "AnalyticsKit",
            dependencies: [],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "AnalyticsKitTests",
            dependencies: ["AnalyticsKit"]
        ),
    ]
)
