// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ProcDock",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "ProcDock", path: "ProcDock", exclude: ["Info.plist", "Resources"]),
    ]
)
