// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScreenshotTrayCore",
    platforms: [.macOS(.v13)],
    products: [.library(name: "ScreenshotTrayCore", targets: ["ScreenshotTrayCore"])],
    targets: [
        .target(name: "ScreenshotTrayCore", path: "ScreenshotTray/Core"),
        .testTarget(name: "ScreenshotTrayCoreTests", dependencies: ["ScreenshotTrayCore"], path: "Tests")
    ]
)
