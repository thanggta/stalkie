// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "CarveCore",
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
  ],
  products: [
    .library(name: "CarveCore", targets: ["CarveCore"]),
    .library(name: "CarveCLILib", targets: ["CarveCLILib"]),
    .library(name: "CarveDamage", targets: ["CarveDamage"]),
    .library(name: "CarveShell", targets: ["CarveShell"]),
    .library(name: "CarveUI", targets: ["CarveUI"]),
    .executable(name: "CarveCLI", targets: ["CarveCLI"]),
  ],
  targets: [
    .target(name: "CarveCore"),
    .target(name: "CarveCLILib", dependencies: ["CarveCore"]),
    .target(name: "CarveDamage", dependencies: ["CarveCore"]),
    .target(name: "CarveShell", dependencies: ["CarveCore"]),
    .target(
      name: "CarveUI",
      dependencies: ["CarveCore", "CarveDamage", "CarveShell"]),
    .executableTarget(name: "CarveCLI", dependencies: ["CarveCLILib"]),
    .testTarget(name: "CarveCoreTests", dependencies: ["CarveCore", "CarveCLILib"]),
    .testTarget(name: "CarveDamageTests", dependencies: ["CarveCore", "CarveDamage"]),
    .testTarget(name: "CarveShellTests", dependencies: ["CarveCore", "CarveShell"]),
  ]
)
