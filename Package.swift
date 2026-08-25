// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "Bitellova",
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
