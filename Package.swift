// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "HabitBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "HabitBar", targets: ["HabitBar"]),
        .executable(name: "HabitBarUITestRunner", targets: ["HabitBarUITestRunner"]),
        .library(name: "HabitBarCore", targets: ["HabitBarCore"])
    ],
    targets: [
        .target(name: "HabitBarCore"),
        .executableTarget(
            name: "HabitBar",
            dependencies: ["HabitBarCore"],
            resources: [.copy("Resources")]
        ),
        .executableTarget(name: "HabitBarUITestRunner"),
        .testTarget(name: "HabitBarCoreTests", dependencies: ["HabitBarCore"])
    ]
)
