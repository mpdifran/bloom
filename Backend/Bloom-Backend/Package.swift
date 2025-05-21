// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Bloom-Backend",
    platforms: [
       .macOS(.v13),
       .iOS(.v17)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.99.3"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/apns.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/redis.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/websocket-kit.git", from: "2.15.0"),
        .package(url: "https://github.com/MihaelIsaev/VaporCron.git", from: "2.6.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        .package(url: "https://github.com/soto-project/soto.git", from: "6.0.0"),
        .package(url: "https://github.com/mpdifran/openai-kit.git", from: "1.6.12"),
        .package(url: "https://github.com/mpdifran/vapor-sign-in-with-apple.git", from: "1.1.0"),
        .package(url: "https://github.com/mpdifran/AppFoundations.git", from: "0.1.6"),
        .package(name: "bloom-model", path: "../../Shared/BloomModel"),
        .package(name: "admin-bloom-model", path: "../../Shared/AdminBloomModel"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "VaporAPNS", package: "apns"),
                .product(name: "Redis", package: "redis"),
                .product(name: "WebSocketKit", package: "websocket-kit"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "OpenAIKit", package: "openai-kit"),
                .product(name: "SignInWithApple", package: "vapor-sign-in-with-apple"),
                .product(name: "SotoS3", package: "soto"),
                .product(name: "AppFoundations", package: "AppFoundations"),
                .product(name: "BloomModel", package: "bloom-model"),
                .product(name: "AdminBloomModel", package: "admin-bloom-model"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .target(name: "App"),
                .product(name: "XCTVapor", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ],
    swiftLanguageModes: [.v5]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("DisableOutwardActorInference"),
    .enableExperimentalFeature("StrictConcurrency"),
] }
