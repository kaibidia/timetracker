// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TimeFlowCore",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "TimeFlowCore", targets: ["TimeFlowCore"])
    ],
    targets: [
        .target(name: "TimeFlowCore"),
        .testTarget(
            name: "TimeFlowCoreTests",
            dependencies: ["TimeFlowCore"]
        )
    ]
)
