// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "CarveCore",
  products: [
    .library(name: "CarveCore", targets: ["CarveCore"]),
    .library(name: "CarveCLILib", targets: ["CarveCLILib"]),
    .executable(name: "CarveCLI", targets: ["CarveCLI"]),
  ],
  targets: [
    .target(name: "CarveCore"),
    .target(name: "CarveCLILib", dependencies: ["CarveCore"]),
    .executableTarget(name: "CarveCLI", dependencies: ["CarveCLILib"]),
    .testTarget(name: "CarveCoreTests", dependencies: ["CarveCore", "CarveCLILib"]),
  ]
)
