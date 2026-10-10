// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "KelvinColor",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
    ],
    products: [
        .library(name: "KelvinColor", targets: ["KelvinColor"]),
    ],
    targets: [
        .target(name: "KelvinColor"),
        .testTarget(name: "KelvinColorTests", dependencies: ["KelvinColor"]),
    ]
)
