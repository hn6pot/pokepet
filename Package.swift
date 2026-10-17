// swift-tools-version:6.0
import PackageDescription

// Two targets: PokepetCore (the logic, tested without a window) and Pokepote (the thin AppKit app « Poképote »).
// The tests live in tests/, at the repository root, mirroring app/.
let package = Package(
    name: "Pokepet",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "PokepetCore", path: "app/PokepetCore"),
        .executableTarget(name: "Pokepote", dependencies: ["PokepetCore"], path: "app/Pokepote"),
        .testTarget(name: "PokepetCoreTests", dependencies: ["PokepetCore"], path: "tests/app/PokepetCore"),
    ]
)
