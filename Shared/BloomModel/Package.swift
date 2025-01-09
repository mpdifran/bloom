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
            targets: ["BloomModel"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/mpdifran/AppFoundations.git", from: "0.1.5")
    ],
    targets: [
        .target(
            name: "BloomModel",
            dependencies: [
                .product(name: "AppFoundations", package: "AppFoundations"),
            ]
        ),
    ]
)
