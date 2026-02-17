// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "apple_vision_aesthetics",
    platforms: [
        .iOS("18.0")
    ],
    products: [
        .library(name: "apple-vision-aesthetics", targets: ["apple_vision_aesthetics"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "apple_vision_aesthetics",
            dependencies: []
        )
    ]
)
