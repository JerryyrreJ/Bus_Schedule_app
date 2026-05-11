// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BusScheduleCore",
    platforms: [
        .iOS(.v18),
        .watchOS(.v10),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "BusScheduleCore",
            targets: ["BusScheduleCore"]
        ),
    ],
    targets: [
        .target(
            name: "BusScheduleCore",
            dependencies: []
        ),
        .testTarget(
            name: "BusScheduleCoreTests",
            dependencies: ["BusScheduleCore"]
        ),
    ]
)
