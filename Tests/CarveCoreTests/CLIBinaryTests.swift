// Tests/CarveCoreTests/CLIBinaryTests.swift
import Foundation
import Testing

/// Executes the prebuilt binary. Never spawns `swift run`/`swift build` from
/// inside a test — that deadlocks on the SwiftPM build lock. CI (and local
/// verification) run `swift build` before `swift test`.
struct CLIBinaryTests {
  @Test func builtBinaryExitsZeroOnRiverside() throws {
    let binaryPath = ".build/debug/CarveCLI"
    guard FileManager.default.isExecutableFile(atPath: binaryPath) else {
      Issue.record("CarveCLI binary not built — run `swift build` before `swift test`.")
      return
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: binaryPath)
    process.arguments = ["cases/riverside"]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    try process.run()
    process.waitUntilExit()
    #expect(process.terminationStatus == 0)
  }
}
