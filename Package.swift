// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "QueueITLibrary",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "QueueITLibrary",
            targets: ["QueueITLibrary"]
        ),
    ],
    targets: [
        .target(
            name: "QueueITLibrary",
            path: "Sources/QueueITLib"
        ),
    ]
)
