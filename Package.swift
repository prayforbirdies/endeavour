// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SuperShuttle",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "SuperShuttle",
            path: "Sources/SuperShuttle"
        )
    ]
)
