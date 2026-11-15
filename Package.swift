// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FloatNotes",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "FloatNotes",
            path: "Sources"
        ),
    ]
)
