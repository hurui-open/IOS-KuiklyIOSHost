// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "kuiklyIOSHost",
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
        .package(path: "OpenKuiklyIOSRender"),
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.21.7"),
    ],
    targets: [
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
