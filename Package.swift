// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "Bitellova",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Bitellova"
        ),
        .testTarget(
            name: "BitellovaTests",
            dependencies: ["Bitellova"]
        )
    ]
)
