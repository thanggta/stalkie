// Tests/CarveCoreTests/CLILogicTests.swift
import Foundation
import Testing
import CarveCLILib

/// Captures lines a CLIRunner instance writes instead of letting them hit
/// FileHandle.standardOutput/standardError, so tests can assert on the text.
final class StreamCapture {
  var text = ""
}

struct CLILogicTests {
  @Test func catalogValidationReturnsZeroForShippedManifest() {
    let out = StreamCapture()
    let err = StreamCapture()
    let code = CLIRunner.run(
      arguments: ["--catalog", "cases/catalog.json"],
      stdout: { out.text.append($0) },
      stderr: { err.text.append($0) })
    #expect(code == 0)
    #expect(out.text.contains("OK  catalog"))
  }

  @Test func validCaseReturnsZeroAndPrintsOk() {
    let out = StreamCapture()
    let err = StreamCapture()
    let code = CLIRunner.run(
      arguments: ["cases/five_minutes"],
      stdout: { out.text.append($0) },
      stderr: { err.text.append($0) })
    #expect(code == 0)
    #expect(out.text.contains("OK  five_minutes"))
    #expect(out.text.contains("gated"))
    #expect(out.text.contains("15 questions"))
  }

  @Test func missingDirectoryReturnsOneAndNamesIt() {
    let out = StreamCapture()
    let err = StreamCapture()
    let code = CLIRunner.run(
      arguments: ["cases/nope"],
      stdout: { out.text.append($0) },
      stderr: { err.text.append($0) })
    #expect(code == 1)
    #expect(err.text.contains("cases/nope"))
  }

  @Test func malformedCaseReturnsOneWithNoCrash() throws {
    // BLOCKER-2 regression at the logic layer: a truncated/invalid case.json
    // must surface as `FAILED` on stderr and return 1 — never a crash.
    let tempRoot = FileManager.default.temporaryDirectory
      .appendingPathComponent("carve-cli-malformed-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: tempRoot) }
    try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)

    // Unterminated JSON — guaranteed invalid. A trailing comma is NOT used:
    // this toolchain's Foundation JSONDecoder tolerates trailing commas, so
    // that fixture would parse and never reach the bare-catch path this test
    // guards.
    let badJSON = #"{"schemaVersion":1,"id":"broken","title":"Broken","sectorMap":[],"verdict":{"questions":[]}"#
    try Data(badJSON.utf8).write(to: tempRoot.appendingPathComponent("case.json"))

    let out = StreamCapture()
    let err = StreamCapture()
    let code = CLIRunner.run(
      arguments: [tempRoot.path],
      stdout: { out.text.append($0) },
      stderr: { err.text.append($0) })
    #expect(code == 1)
    #expect(err.text.contains("FAILED"))
    #expect(!err.text.contains("Fatal error"))
  }

  @Test func trailingCommaInCaseJSONFailsStrictCheck() throws {
    // Regression: Foundation's JSONDecoder tolerates trailing commas, so this
    // used to validate and exit 0. "CarveCLI passed" must mean the JSON is
    // actually valid — the strict check makes that true.
    let tempRoot = FileManager.default.temporaryDirectory
      .appendingPathComponent("carve-cli-trailing-comma-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: tempRoot) }
    try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)

    let sloppyJSON = #"""
    {"schemaVersion":1,"id":"sloppy","title":"Sloppy",
     "sectorMap":[],"verdict":{"questions":[]},}
    """#
    try Data(sloppyJSON.utf8).write(to: tempRoot.appendingPathComponent("case.json"))

    let out = StreamCapture()
    let err = StreamCapture()
    let code = CLIRunner.run(
      arguments: [tempRoot.path],
      stdout: { out.text.append($0) },
      stderr: { err.text.append($0) })
    #expect(code == 1)
    #expect(err.text.contains("strict JSON"))
  }

  @Test func validationProblemsReturnOneAndListThem() throws {
    // Rule 9: the valid-case test would still pass if CLIRunner stopped
    // calling validateCase. This fixture parses but FAILS validation, so the
    // OK gate must actually depend on problems.isEmpty.
    let tempRoot = FileManager.default.temporaryDirectory
      .appendingPathComponent("carve-cli-invalid-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: tempRoot) }
    try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)

    // Empty sectorMap + empty verdict.questions: parses cleanly, then
    // validateCase reports "at least one verdict question".
    let invalidJSON = #"""
    {"schemaVersion":1,"id":"invalid","title":"Invalid","sectorMap":[],"verdict":{"questions":[]}}
    """#
    try Data(invalidJSON.utf8).write(to: tempRoot.appendingPathComponent("case.json"))

    let out = StreamCapture()
    let err = StreamCapture()
    let code = CLIRunner.run(
      arguments: [tempRoot.path],
      stdout: { out.text.append($0) },
      stderr: { err.text.append($0) })
    #expect(code == 1)
    #expect(err.text.contains("FAILED"))
    #expect(err.text.contains("problem(s):"))
    #expect(err.text.contains("verdict question"))
    #expect(err.text.contains("  • "))
  }
}
