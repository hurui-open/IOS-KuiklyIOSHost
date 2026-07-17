// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "KuiklyIOSHost",
    defaultLocalization: "zh-Hans",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "KuiklyIOSHost",
            targets: ["KuiklyIOSHost"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.21.7"),
    ],
    targets: [
        .target(
            name: "OpenKuiklyIOSRender",
            path: "Sources/OpenKuiklyIOSRender",
            publicHeadersPath: "core-render-ios",
            cSettings: [
                "core-render-ios",
                "core-render-ios/Core",
                "core-render-ios/Extension",
                "core-render-ios/Extension/AdvancedComps",
                "core-render-ios/Extension/AdvancedComps/LiquidGlass",
                "core-render-ios/Extension/BridgeProtocol",
                "core-render-ios/Extension/Category",
                "core-render-ios/Extension/Components",
                "core-render-ios/Extension/Components/Base",
                "core-render-ios/Extension/Components/NestScroll",
                "core-render-ios/Extension/Modules",
                "core-render-ios/Extension/Vendor",
                "core-render-ios/Handler",
                "core-render-ios/Handler/KuiklyTurboDisplay",
                "core-render-ios/MacSupport",
                "core-render-ios/Performance",
                "core-render-ios/Protocol",
                "core-render-ios/TDFCommon",
                "core-render-ios/Thread",
                "core-render-ios/View",
            ].map { .headerSearchPath($0) }
        ),
        .target(
            name: "KuiklyIOSHost",
            dependencies: [
                "OpenKuiklyIOSRender",
                .product(name: "SDWebImage", package: "SDWebImage"),
            ],
            path: "Sources/KuiklyIOSHost",
            publicHeadersPath: "PublicHeaders",
            cSettings: [
                "PublicHeaders",
                "Internal",
                "Router",
            ].map { .headerSearchPath($0) }
        ),
        .testTarget(
            name: "KuiklyIOSHostTests",
            dependencies: ["KuiklyIOSHost"],
            path: "Tests/KuiklyIOSHostTests"
        ),
    ]
)
