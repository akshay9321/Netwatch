// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NetWatch",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "NetWatch",
            path: "Sources/NetWatch"
        )
    ]
)
