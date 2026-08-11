// Tests/CarveCoreTests/E2ERiversideTests.swift
import Foundation
import Testing
@testable import CarveCore

/// Ports test/e2e/riverside_test.dart. `cases/riverside` is the shared fixture;
/// `swift test` runs with CWD = package root (verified).
private func loadRiverside() throws -> CaseFile {
  let dir = "cases/riverside"
  let manifestData = try #require(
    FileManager.default.contents(atPath: "\(dir)/case.json"),
    "case.json not found — run `swift test` from the package root")

  var fragmentFiles: [(name: String, data: Data)] = []
  let fragmentsDir = "\(dir)/fragments"
  if let names = try? FileManager.default.contentsOfDirectory(atPath: fragmentsDir) {
    for name in names.sorted() where name.hasSuffix(".json") {
      if let data = FileManager.default.contents(atPath: "\(fragmentsDir)/\(name)") {
        fragmentFiles.append((name: name, data: data))
      }
    }
  } else {
    throw CaseFormatError("\(fragmentsDir) not found — run `swift test` from the package root")
  }

  return try parseCase(manifestData: manifestData, fragmentFiles: fragmentFiles)
}

struct E2ERiversideTests {
  @Test func riversideParsesAndPassesEveryValidatorCheck() throws {
    let c = try loadRiverside()
    let problems = validateCase(c)
    #expect(problems.isEmpty, "validator problems: \(problems)")
  }

  @Test func riversidePlaysToCorrectVerdictWithinBudget() throws {
    let c = try loadRiverside()
    var engine = CarveEngine(caseFile: c)

    // thread_001 costs 8 of a 20-cycle budget. If the carve step stopped
    // being load-bearing (e.g. costs were dropped), cyclesRemaining would
    // drift from 12 and this case would no longer be a scarcity exercise.
    #expect(engine.carve("thread_001").outcome == .ok)
    engine.link("adrian", "priya")

    let report = scoreVerdict(c, ["q_who": "priya"])
    #expect(report.accuracy == 1.0)
    #expect(engine.cyclesRemaining == 12)
  }

  @Test func riversideCannotBeFullyRecoveredScarcityHolds() throws {
    let c = try loadRiverside()
    #expect(c.totalCarveCost > c.cycleBudget)
  }
}
