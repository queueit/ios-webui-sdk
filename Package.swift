// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "QueueITLibrary",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "QueueITLibrary",
            targets: ["QueueITLibrary"]),
    ],
    targets: [
        .target(
            name: "QueueITLibrary",
            path: "QueueItLib/",
            publicHeadersPath: ""
        )
    ]
)
