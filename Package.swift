// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WorkWife",
    platforms: [.macOS("14.2")],
    targets: [
        .executableTarget(name: "WorkWife", path: "Sources/WorkWife")
    ]
)
