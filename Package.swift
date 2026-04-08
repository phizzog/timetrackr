// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TimeTrackr",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "TimeTrackrCore",
            targets: ["TimeTrackrCore"]
        ),
        .executable(
            name: "TimeTrackr",
            targets: ["TimeTrackrApp"]
        )
    ],
    targets: [
        .target(
            name: "TimeTrackrCore"
        ),
        .executableTarget(
            name: "TimeTrackrApp",
            dependencies: ["TimeTrackrCore"]
        ),
        .testTarget(
            name: "TimeTrackrTests",
            dependencies: ["TimeTrackrCore"]
        )
    ]
)
