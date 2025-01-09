// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "admin-bloom-model",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "AdminBloomModel",
            targets: ["AdminBloomModel"]
        ),
    ],
    dependencies: [
        .package(name: "bloom-model", path: "../../Shared/BloomModel"),
    ],
    targets: [
        .target(
            name: "AdminBloomModel",
            dependencies: [
              .product(name: "BloomModel", package: "bloom-model"),
            ]
        ),
    ]
)
