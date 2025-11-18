// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HabitTracker",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "HabitTracker",
            targets: ["HabitTracker"]
        ),
    ],
    dependencies: [
        // The Composable Architecture
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture.git",
            from: "1.23.1"
        ),
        // Supabase Swift Client
        .package(
            url: "https://github.com/supabase/supabase-swift.git",
            from: "2.0.0"
        ),
        // SwiftLint for code quality
        .package(
            url: "https://github.com/realm/SwiftLint.git",
            from: "0.54.0"
        ),
        // Dependencies (TCA dependency management)
        .package(
            url: "https://github.com/pointfreeco/swift-dependencies.git",
            from: "1.0.0"
        ),
        // Identified Collections
        .package(
            url: "https://github.com/pointfreeco/swift-identified-collections.git",
            from: "1.0.0"
        ),
    ],
    targets: [
        .target(
            name: "HabitTracker",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
            ],
            path: "Sources/HabitTracker",
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("ForwardTrailingClosures"),
                .enableUpcomingFeature("ImplicitOpenExistentials"),
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "HabitTrackerTests",
            dependencies: [
                "HabitTracker",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Tests/HabitTrackerTests"
        ),
    ]
)
