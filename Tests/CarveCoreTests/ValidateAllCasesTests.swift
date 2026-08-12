// Tests/CarveCoreTests/ValidateAllCasesTests.swift
import Foundation
import Testing
@testable import CarveCore

/// Loads one case directory. Same pattern as E2EFiveMinutesTests, generalised to
/// any directory under `cases/`. `swift test` runs with CWD = package root
/// (verified), which is also the CI precondition.
private func loadCase(at dir: String) throws -> CaseFile {
  let manifestData = try #require(
    FileManager.default.contents(atPath: "\(dir)/case.json"),
    "case.json not found in \(dir) — run `swift test` from the package root")

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

struct ValidateAllCasesTests {
  /// INV-3…INV-5 run against every case directory, so a newly authored case
  /// cannot silently break the invariants. Picking up future cases is what
  /// this test is for — keep it independent of any id.
  @Test func everyCaseUnderCasesPassesEveryInvariant() throws {
    let casesDir = "cases"
    guard let entries = try? FileManager.default.contentsOfDirectory(atPath: casesDir) else {
      Issue.record("cases/ directory not found — run `swift test` from the package root")
      return
    }

    let caseDirs = entries
      .sorted()
      .filter { FileManager.default.fileExists(atPath: "\(casesDir)/\($0)/case.json") }

    #expect(
      !caseDirs.isEmpty,
      "no cases/ subdirectories contain a case.json — the enumeration matched nothing")

    for dir in caseDirs {
      let c: CaseFile
      do {
        c = try loadCase(at: "\(casesDir)/\(dir)")
      } catch let e as CaseFormatError {
        throw CaseFormatError("case \(dir): \(e.message)")
      } catch {
        throw CaseFormatError("case \(dir): \(error)")
      }
      let problems = validateCase(c)
      #expect(problems.isEmpty, "case \(c.id): validator problems: \(problems)")
    }
  }
}
