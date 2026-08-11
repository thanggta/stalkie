// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "CarveCore",
  products: [
    .library(name: "CarveCore", targets: ["CarveCore"]),
    .executable(name: "CarveCLI", targets: ["CarveCLI"]),
  ],
  targets: [
    .target(name: "CarveCore"),
    .executableTarget(name: "CarveCLI", dependencies: ["CarveCore"]),
    .testTarget(name: "CarveCoreTests", dependencies: ["CarveCore"]),
  ]
)
