// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "QueueITLib",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "QueueITLib",
            targets: ["QueueITLib"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "QueueITLib",
            dependencies: []),
        .testTarget(
            name: "QueueITLibTests",
            dependencies: ["QueueITLib"])
    ],
    swiftLanguageVersions: [
        .version("5")
    ]
)
