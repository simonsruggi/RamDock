// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RamDock",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "RamDock", path: "RamDock", exclude: ["Info.plist", "Resources"]),
    ]
)
