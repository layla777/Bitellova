// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "Bitellova",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "Bitellova",
            targets: ["Bitellova"]
        ),
        .executable(
            name: "bitellova-profile",
            targets: ["BitellovaProfile"]
        ),
    ],
    targets: [
        .target(
            name: "Bitellova"
        ),
        .executableTarget(
            name: "BitellovaProfile",
            dependencies: ["Bitellova"]
        ),
        .testTarget(
            name: "BitellovaTests",
            dependencies: ["Bitellova"]
        ),
    ]
)
