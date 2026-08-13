// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "IPTVKit",
    // MVP: iPhone. macOS se declara solo para poder testear los módulos headless en CI
    // (`swift test`, sin simulador). La app real es iOS; iPad/tvOS, fase posterior.
    platforms: [
        .iOS(.v18),
        .macOS(.v14),
    ],
    products: [
        // Cada módulo se expone como producto para poder linkarlo de forma granular
        // (el target de tvOS reutilizará Core/Networking/Persistence/PlayerKit tal cual).
        .library(name: "IPTVCore", targets: ["IPTVCore"]),
        .library(name: "IPTVNetworking", targets: ["IPTVNetworking"]),
        .library(name: "IPTVPersistence", targets: ["IPTVPersistence"]),
        .library(name: "IPTVPlayerKit", targets: ["IPTVPlayerKit"]),
        .library(name: "IPTVDesignSystem", targets: ["IPTVDesignSystem"]),
        .library(name: "IPTVFeatures", targets: ["IPTVFeatures"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.15.0"),
        // Core e implementaciones solo necesitan la capa de inyección, no todo TCA.
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.4.0"),
    ],
    targets: [
        // MARK: - Dominio puro (sin UI, sin red, sin persistencia)
        .target(
            name: "IPTVCore",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
            ]
        ),
        .testTarget(name: "IPTVCoreTests", dependencies: ["IPTVCore"]),

        // MARK: - Red (Xtream Codes). Depende solo de los protocolos de Core.
        .target(
            name: "IPTVNetworking",
            dependencies: [
                "IPTVCore",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .testTarget(name: "IPTVNetworkingTests", dependencies: ["IPTVNetworking"]),

        // MARK: - Persistencia (SwiftData cache + repositorios).
        .target(
            name: "IPTVPersistence",
            dependencies: [
                "IPTVCore",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),

        // MARK: - Reproducción (wrapper AVPlayer detrás de PlayerEngine).
        .target(
            name: "IPTVPlayerKit",
            dependencies: [
                "IPTVCore",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),

        // MARK: - Design System (componentes UI reutilizables + tokens).
        .target(
            name: "IPTVDesignSystem",
            dependencies: []
        ),

        // MARK: - Features TCA. La única capa que conoce ComposableArchitecture.
        .target(
            name: "IPTVFeatures",
            dependencies: [
                "IPTVCore",
                "IPTVNetworking",
                "IPTVPersistence",
                "IPTVPlayerKit",
                "IPTVDesignSystem",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .testTarget(
            name: "IPTVFeaturesTests",
            dependencies: [
                "IPTVFeatures",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
    ]
)
