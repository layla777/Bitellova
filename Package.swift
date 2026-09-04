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
        .executable(
            name: "bitellova-arena",
            targets: ["BitellovaArena"]
        ),
        .library(
            name: "BitellovaAI",
            targets: ["BitellovaAI"]
        ),
    ],
    targets: [
        .target(
            name: "Bitellova"
        ),
        .executableTarget(
            name: "BitellovaProfile",
            dependencies: [
                "Bitellova",
                "BitellovaAI",
            ],
        ),
        .executableTarget(
            name: "BitellovaArena",
            dependencies: [
                "Bitellova",
                "BitellovaAI",
            ],
        ),
        .testTarget(
            name: "BitellovaTests",
            dependencies: ["Bitellova"]
        ),
        .target(
            name: "BitellovaAI",
            dependencies: ["Bitellova"]
        ),
        .testTarget(
            name: "BitellovaAITests",
            dependencies: [
                "Bitellova",
                "BitellovaAI",
            ]
        ),
    ]
)
