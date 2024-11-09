// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "bloom-model",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "BloomModel",
            targets: ["BloomModel"]),
    ],
    targets: [
        .target(
            name: "BloomModel"),
    ]
)
