// Tests/CarveShellTests/CaseLaunchTests.swift
// Why: a second case cannot be played if launch still hardcodes one id.
// Discovery + -caseId must work for any bundled directory.

import Foundation
import Testing
@testable import CarveCore
@testable import CarveShell

struct CaseLaunchTests {
  @Test func missingLaunchArgumentUsesProductionDefault() {
    #expect(CaseLaunch.resolvedCaseId(arguments: ["Carve"]) == CaseLaunch.productionDefault)
    #expect(CaseLaunch.productionDefault == "five_minutes")
  }

  @Test func caseIdArgumentSelectsAnyDiscoveredId() {
    let args = ["Carve", "-caseId", "other_case"]
    #expect(CaseLaunch.resolvedCaseId(arguments: args) == "other_case")
  }

  @Test func caseIdArgumentIgnoresFlagWithoutValue() {
    #expect(CaseLaunch.resolvedCaseId(arguments: ["Carve", "-caseId"]) == CaseLaunch.productionDefault)
  }

  @Test func discoversEveryDirectoryWithCaseJSON() throws {
    let root = FileManager.default.temporaryDirectory
      .appendingPathComponent("carve-catalog-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    try writeCaseStub(in: root, id: "alpha")
    try writeCaseStub(in: root, id: "beta")
    try FileManager.default.createDirectory(
      at: root.appendingPathComponent("not_a_case"),
      withIntermediateDirectories: true)

    #expect(CaseLaunch.discoverCaseIds(in: root) == ["alpha", "beta"])
  }

  @Test func snapshotsAreIsolatedByCaseId() throws {
    let dir = FileManager.default.temporaryDirectory
      .appendingPathComponent("carve-isolate-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }

    let caseA = try loadFiveMinutes()
    let sessionA = GameSession(caseFile: caseA)
    #expect(sessionA.openFragment("thread_theo").outcome == .ok)

    let storeA = FileSessionStore(
      directory: dir,
      fileName: FileSessionStore.snapshotFileName(caseId: caseA.id))
    try storeA.save(sessionA.makeSnapshot())

    let storeB = FileSessionStore(
      directory: dir,
      fileName: FileSessionStore.snapshotFileName(caseId: "other_case"))
    #expect(try storeB.load() == nil, "another case must not restore this progress")

    let reloaded = try #require(try storeA.load())
    #expect(reloaded.caseId == caseA.id)
    #expect(reloaded.carvedIds.contains("thread_theo"))
  }

  @Test func showCasePickerIsOptIn() {
    #expect(CaseLaunch.shouldShowPicker(arguments: ["Carve"]) == false)
    #expect(CaseLaunch.shouldShowPicker(arguments: ["Carve", "-showCasePicker"]) == true)
  }
}

private func writeCaseStub(in root: URL, id: String) throws {
  let dir = root.appendingPathComponent(id, isDirectory: true)
  try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
  try Data("{\"id\":\"\(id)\"}".utf8).write(to: dir.appendingPathComponent("case.json"))
}

private func loadFiveMinutes() throws -> CaseFile {
  let dir = "cases/five_minutes"
  let manifestData = try #require(
    FileManager.default.contents(atPath: "\(dir)/case.json"),
    "case.json not found — run `swift test` from the package root")
  var fragmentFiles: [(name: String, data: Data)] = []
  let fragmentsDir = "\(dir)/fragments"
  let names = try FileManager.default.contentsOfDirectory(atPath: fragmentsDir)
  for name in names.sorted() where name.hasSuffix(".json") {
    if let data = FileManager.default.contents(atPath: "\(fragmentsDir)/\(name)") {
      fragmentFiles.append((name: name, data: data))
    }
  }
  return try parseCase(manifestData: manifestData, fragmentFiles: fragmentFiles)
}
