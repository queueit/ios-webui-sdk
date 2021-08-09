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
            path: "QueueITLib",
            publicHeadersPath: "include")
    ],
    swiftLanguageVersions: [
        .version("5")
    ]
)
