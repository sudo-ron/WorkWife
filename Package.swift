// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WorkWife",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "WorkWife", path: "Sources/WorkWife")
    ]
)
