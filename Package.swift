// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TinyPlayer6",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "TinyPlayer6",
            targets: ["TinyPlayer6"]),
    ],
    targets: [
        .target(
            name: "TinyPlayer6"),
    ]
)
