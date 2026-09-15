// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Endeavour",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Endeavour",
            path: "Sources/Endeavour"
        )
    ]
)
