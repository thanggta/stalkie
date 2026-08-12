// Tests/CarveShellTests/AppReadinessTests.swift
// Why: Links and Decide must appear from generic state, not case ids.
// Hiding them cannot deadlock filing.

import Foundation
import Testing
import CarveCore
@testable import CarveShell

struct AppReadinessTests {
  @Test func linksHiddenUntilTwoEntitiesExist() throws {
    let caseFile = try loadCase("five_minutes")
    var engine = CarveEngine(caseFile: caseFile)
    #expect(!AppReadiness.linksReady(entities: EntityDerivation.entities(from: caseFile, carvedIds: engine.carvedIds)))

    #expect(engine.carve("thread_theo").outcome == .ok)
    let afterTheo = EntityDerivation.entities(from: caseFile, carvedIds: engine.carvedIds)
    #expect(AppReadiness.linksReady(entities: afterTheo))
  }

  @Test func decideHiddenUntilAuthoredPredicate() throws {
    let caseFile = try loadCase("five_minutes")
    var engine = CarveEngine(caseFile: caseFile)
    #expect(!AppReadiness.decideReady(caseFile: caseFile, state: engine.state))

    #expect(engine.carve("thread_theo").outcome == .ok)
    #expect(!AppReadiness.decideReady(caseFile: caseFile, state: engine.state))

    #expect(engine.carve("thread_sable").outcome == .ok)
    #expect(AppReadiness.decideReady(caseFile: caseFile, state: engine.state))
  }

  @Test func decideReadyWhenCannotUseAnswered() throws {
    let caseFile = try loadCase("five_minutes")
    let broken = CaseFile(
      schemaVersion: caseFile.schemaVersion,
      id: caseFile.id,
      title: caseFile.title,
      ownerEntityId: caseFile.ownerEntityId,
      decideReadyWhen: ["answered": .string("q_sable_who")],
      sectorMap: caseFile.sectorMap,
      questions: caseFile.questions,
      fragments: caseFile.fragments)
    let problems = AppReadiness.validateDecideReadiness(broken)
    #expect(problems.contains(where: { $0.contains("answered") }))
  }

  @Test func shippedCasesDecidePredicateIsReachable() throws {
    for id in ["five_minutes", "dont_wait_up"] {
      let caseFile = try loadCase(id)
      #expect(AppReadiness.validateDecideReadiness(caseFile).isEmpty)
      let problems = validateCase(caseFile)
      #expect(problems.isEmpty)
    }
  }
}

private func loadCase(_ id: String) throws -> CaseFile {
  let dir = "cases/\(id)"
  let manifestData = try #require(FileManager.default.contents(atPath: "\(dir)/case.json"))
  var fragmentFiles: [(name: String, data: Data)] = []
  let names = try FileManager.default.contentsOfDirectory(atPath: "\(dir)/fragments")
  for name in names.sorted() where name.hasSuffix(".json") {
    if let data = FileManager.default.contents(atPath: "\(dir)/fragments/\(name)") {
      fragmentFiles.append((name: name, data: data))
    }
  }
  return try parseCase(manifestData: manifestData, fragmentFiles: fragmentFiles)
}
